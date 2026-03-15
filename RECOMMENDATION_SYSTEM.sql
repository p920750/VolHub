-- ==============================================================================
-- HYBRID RECOMMENDATION SYSTEM ALGORITHMS (CONTENT + COLLABORATIVE)
-- ==============================================================================

-- 1. Enable Full-Text Search and fuzzy matching extension (optional but good for future)
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- 2. Volunteer Inexperienced -> Experienced Auto-Promotion Trigger
-- Promotes volunteers to 'experienced' if they have >= 10 completed events and >= 5 certificates.
CREATE OR REPLACE FUNCTION check_and_promote_volunteer()
RETURNS TRIGGER AS $$
DECLARE
    v_completed_count INT;
    v_cert_count INT;
BEGIN
    -- Only check for inexperienced volunteers
    IF NEW.volunteer_type = 'inexperienced' THEN
        -- Count completed events for this volunteer
        SELECT count(*) INTO v_completed_count 
        FROM event_applications 
        WHERE volunteer_id = NEW.id AND status = 'completed';

        -- Get number of certificates
        v_cert_count := coalesce(array_length(NEW.certificates, 1), 0);

        -- Check promotion criteria
        IF v_completed_count >= 10 AND v_cert_count >= 5 THEN
            NEW.volunteer_type := 'experienced';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_promote_volunteer ON users;
CREATE TRIGGER trigger_promote_volunteer
BEFORE UPDATE ON users
FOR EACH ROW
WHEN (OLD.volunteer_type = 'inexperienced')
EXECUTE FUNCTION check_and_promote_volunteer();

-- ==============================================================================
-- RPC 1: Recommend Events for Inexperienced Volunteer (Small/Easy Events)
-- ==============================================================================
CREATE OR REPLACE FUNCTION recommend_events_for_inexperienced_volunteer(p_user_id UUID)
RETURNS SETOF events AS $$
DECLARE
    v_user_skills text;
    v_user_query tsquery;
BEGIN
    -- Extract skills and interests, format them with ' OR ' for websearch_to_tsquery
    SELECT expand_keywords_for_search(lower(coalesce(array_to_string(skills, ' '), '') || ' ' || coalesce(array_to_string(interests, ' '), '')))
    INTO v_user_skills
    FROM users WHERE id = p_user_id;

    IF v_user_skills IS NOT NULL AND v_user_skills != '' THEN
        v_user_query := websearch_to_tsquery('english', v_user_skills);
    ELSE
        v_user_query := to_tsquery('english', '');
    END IF;

    RETURN QUERY
    WITH EventScores AS (
        SELECT 
            e.id,
            -- Content Score (Full-Text Search matches root words like 'teach' and 'teaching' automatically)
            ts_rank(to_tsvector('english', coalesce(e.requirements, '') || ' ' || array_to_string(e.categories, ' ') || ' ' || array_to_string(e.skills_required, ' ')), v_user_query) AS content_score,
            
            -- Collaborative Score: How many other inexperienced users applied to this event?
            (
                SELECT count(DISTINCT ea.volunteer_id) 
                FROM event_applications ea
                JOIN users u ON u.id = ea.volunteer_id
                WHERE ea.event_id = e.id 
                  AND u.volunteer_type = 'inexperienced'
            ) AS collaborative_score
        FROM events e
        WHERE e.status = 'upcoming'
          -- Hard Filter: Only "small/easy" events for inexperienced users
          -- Heuristic: needs less than 20 volunteers, or has 'beginner', 'easy' in categories.
          -- (Adjust conditions based on actual business logic, here we favor events needing small groups)
          AND (e.volunteers_needed > 0 AND e.volunteers_needed <= 50)
          
          -- Exclude already applied events
          AND NOT EXISTS (
              SELECT 1 FROM event_applications ea 
              WHERE ea.event_id = e.id AND ea.volunteer_id = p_user_id
          )
    )
    SELECT e.*
    FROM events e
    JOIN EventScores es ON e.id = es.id
    -- Hybrid scoring: Combine Content Match with Collaborative Popularity
    ORDER BY (es.content_score * 10.0 + es.collaborative_score * 0.5) DESC, e.created_at DESC
    LIMIT 20;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ==============================================================================
-- RPC 2: Recommend Events for Experienced Volunteer
-- ==============================================================================
CREATE OR REPLACE FUNCTION recommend_events_for_experienced_volunteer(p_user_id UUID)
RETURNS SETOF events AS $$
DECLARE
    v_user_skills text;
    v_user_query tsquery;
    v_user_rating numeric;
    v_user_rank numeric;
BEGIN
    SELECT 
        expand_keywords_for_search(lower(coalesce(array_to_string(skills, ' '), '') || ' ' || coalesce(array_to_string(interests, ' '), ''))),
        coalesce(received_rating, 0),
        coalesce(rank_score, 0)
    INTO v_user_skills, v_user_rating, v_user_rank
    FROM users WHERE id = p_user_id;

    IF v_user_skills IS NOT NULL AND v_user_skills != '' THEN
        v_user_query := websearch_to_tsquery('english', v_user_skills);
    ELSE
        v_user_query := to_tsquery('english', '');
    END IF;

    RETURN QUERY
    WITH EventScores AS (
        SELECT 
            e.id,
            -- Content Score
            ts_rank(to_tsvector('english', coalesce(e.requirements, '') || ' ' || array_to_string(e.categories, ' ') || ' ' || array_to_string(e.skills_required, ' ')), v_user_query) AS content_score,
            
            -- Collaborative Score (User-User similarity based on past applications)
            (
                SELECT count(DISTINCT ea_other.volunteer_id) 
                FROM event_applications ea_other
                JOIN event_applications ea_past ON ea_other.volunteer_id = ea_past.volunteer_id
                JOIN event_applications ea_user ON ea_user.event_id = ea_past.event_id
                WHERE ea_other.event_id = e.id 
                  AND ea_user.volunteer_id = p_user_id
                  AND ea_other.volunteer_id != p_user_id
            ) AS collaborative_score
            
        FROM events e
        WHERE e.status = 'upcoming'
          -- Exclude already applied events
          AND NOT EXISTS (
              SELECT 1 FROM event_applications ea 
              WHERE ea.event_id = e.id AND ea.volunteer_id = p_user_id
          )
    )
    SELECT e.*
    FROM events e
    JOIN EventScores es ON e.id = es.id
    -- Hybrid Formula: Content + Collaborative + Bonus Multiplier (Rating/Rank)
    ORDER BY ((es.content_score * 10.0) + (es.collaborative_score * 2.0)) * (1.0 + (v_user_rating / 5.0) + (v_user_rank / 100.0)) DESC, e.created_at DESC
    LIMIT 20;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ==============================================================================
-- RPC 3: Recommend Volunteers for Manager (Specific Event)
-- ==============================================================================
CREATE OR REPLACE FUNCTION recommend_volunteers_for_manager(p_manager_id UUID, p_event_id UUID)
RETURNS SETOF users AS $$
DECLARE
    v_event_reqs text;
    v_event_query tsquery;
BEGIN
    -- Extract event requirements
    SELECT expand_keywords_for_search(lower(coalesce(requirements, '') || ' ' || array_to_string(categories, ' ') || ' ' || array_to_string(skills_required, ' ')))
    INTO v_event_reqs
    FROM events WHERE id = p_event_id;

    IF v_event_reqs IS NOT NULL AND v_event_reqs != '' THEN
        v_event_query := websearch_to_tsquery('english', v_event_reqs);
    ELSE
        v_event_query := to_tsquery('english', '');
    END IF;

    RETURN QUERY
    WITH VolunteerScores AS (
        SELECT 
            u.id,
            -- Content Score: Event requirements against Volunteer skills
            ts_rank(to_tsvector('english', coalesce(array_to_string(u.skills, ' '), '') || ' ' || coalesce(array_to_string(u.interests, ' '), '')), v_event_query) AS content_score,
            
            -- Collaborative Score: Has this volunteer successfully worked for this manager before? -> Huge Boost
            (
                SELECT count(*) 
                FROM event_applications ea
                JOIN events ev ON ev.id = ea.event_id
                WHERE ea.volunteer_id = u.id 
                  AND ev.assigned_manager_id = p_manager_id
                  AND ea.status = 'completed'
            ) AS past_success_score
            
        FROM users u
        WHERE u.role = 'volunteer'
          -- Optionally filter by those who ARE registered for this event if you only want to sort applicants.
          -- If you want to suggest ANY volunteer globally to invite, we search all volunteers.
          -- The prompt says "among the registered volunteers who are registered for the event". Let's enforce that.
          AND EXISTS (
              SELECT 1 FROM event_applications ea 
              WHERE ea.volunteer_id = u.id AND ea.event_id = p_event_id
          )
    )
    SELECT u.*
    FROM users u
    JOIN VolunteerScores vs ON u.id = vs.id
    -- Hybrid Formula: Content matching + Past Success history + Rating/Certificates
    ORDER BY (
        (vs.content_score * 10.0) + 
        (vs.past_success_score * 50.0) +  -- Massive heavy weight for past success
        (coalesce(u.received_rating, 0) * 2.0) +
        (coalesce(array_length(u.certificates, 1), 0) * 1.0)
    ) DESC
    LIMIT 50;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ==============================================================================
-- RPC 4: Recommend Managers for Organizer
-- ==============================================================================
CREATE OR REPLACE FUNCTION recommend_managers_for_organizer(p_organizer_id UUID)
RETURNS SETOF users AS $$
DECLARE
    v_org_history text;
    v_org_query tsquery;
BEGIN
    -- Extract what kind of events the organizer usually posts to match with Manager's company_category
    SELECT expand_keywords_for_search(lower(string_agg(coalesce(array_to_string(categories, ' '), ''), ' ')))
    INTO v_org_history
    FROM events WHERE user_id = p_organizer_id;

    IF v_org_history IS NOT NULL AND v_org_history != '' THEN
        v_org_query := websearch_to_tsquery('english', v_org_history);
    ELSE
        v_org_query := to_tsquery('english', '');
    END IF;

    RETURN QUERY
    WITH ManagerScores AS (
        SELECT 
            m.id,
            -- Content Score: Match organizer's past event categories with manager's company_category
            ts_rank(to_tsvector('english', coalesce(array_to_string(m.company_category, ' '), '')), v_org_query) AS content_score,
            
            -- Collaborative Score: How many volunteers has this manager successfully guided globally?
            (
                SELECT count(*) 
                FROM event_applications ea
                JOIN events ev ON ev.id = ea.event_id
                WHERE ev.assigned_manager_id = m.id AND ea.status = 'completed'
            ) AS global_volunteers_managed,
            
            -- Past Success explicitly with THIS organizer
            (
                SELECT count(*) 
                FROM events ev
                WHERE ev.assigned_manager_id = m.id AND ev.user_id = p_organizer_id AND ev.status = 'completed'
            ) AS past_success_with_org
            
        FROM users m
        WHERE m.role = 'event_manager' OR m.role = 'manager'
    )
    SELECT m.*
    FROM users m
    JOIN ManagerScores ms ON m.id = ms.id
    -- Rank by Rating + Past successful completions + Content match
    ORDER BY (
        (coalesce(m.received_rating, 0) * 10.0) +
        (ms.content_score * 5.0) +
        (ms.global_volunteers_managed * 1.0) +
        (ms.past_success_with_org * 50.0) -- Massive weight for successful past partnership
    ) DESC
    LIMIT 20;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==============================================================================
-- PERFORMANCE INDEXING (Using GIN directly on text arrays)
-- ==============================================================================
CREATE INDEX IF NOT EXISTS idx_users_skills_gin ON users USING GIN (skills);
CREATE INDEX IF NOT EXISTS idx_users_interests_gin ON users USING GIN (interests);
CREATE INDEX IF NOT EXISTS idx_events_categories_gin ON events USING GIN (categories);
CREATE INDEX IF NOT EXISTS idx_events_skills_req_gin ON events USING GIN (skills_required);

