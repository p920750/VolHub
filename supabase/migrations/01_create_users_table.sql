-- Create the users table
CREATE TABLE public.users (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL PRIMARY KEY,
    role text not null check (role in ('volunteer', 'organizer', 'manager', 'admin')),
    volunteer_type text check (volunteer_type in ('experienced', 'inexperienced')),

    -- Common Data
    full_name TEXT,
    email TEXT,
    profile_photo TEXT, -- URL to storage
    date_of_birth DATE,
    country_code TEXT,
    phone_number TEXT,
    address TEXT,
    is_email_verified BOOLEAN DEFAULT FALSE,
    is_phone_verified BOOLEAN DEFAULT FALSE,
    profile_completeness NUMERIC DEFAULT 0,
    
    -- Event Organizers & Volunteers Shared Data
    aadhar_pdf TEXT, -- URL to storage
    is_aadhar_verified BOOLEAN DEFAULT FALSE,
    
    -- Volunteer Specific Data
    skills TEXT[],
    interests TEXT[],
    certificates TEXT[], -- URLs to PDFs
    -- volunteer_type is defined above
    
    -- Ratings & Scores (Shared for Volunteer & Manager)
    -- Volunteer: reviews from managers, received rating from manager
    -- Manager: received rating from organizer
    rank_score NUMERIC,
    received_rating NUMERIC, -- Rating value (e.g., 4.5)
    rating_out_of NUMERIC,   -- Max rating value (e.g., 5.0)
    reviews JSONB, -- List of reviews
    
    -- Event Manager Specific Data
    company_name TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable Row Level Security
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Policies (Low Security / Permissive as requested)

-- 1. Public Read Access: Everyone can view profiles (needed for social features/discovery)
CREATE POLICY "Public profiles are viewable by everyone"
    ON public.users FOR SELECT
    USING (true);

-- 2. Insert Access: Users can insert their own profile during signup
CREATE POLICY "Users can insert their own profile"
    ON public.users FOR INSERT
    WITH CHECK (auth.uid() = id);

-- 3. Update Access: Users can update their own profile
CREATE POLICY "Users can update own profile"
    ON public.users FOR UPDATE
    USING (auth.uid() = id);

-- 4. Delete Access: Users can delete their own profile
CREATE POLICY "Users can delete own profile"
    ON public.users FOR DELETE
    USING (auth.uid() = id);

-- Function to handle new user creation from auth.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  user_role TEXT;
  user_dob DATE;
BEGIN
  -- Extract role from metadata, default to 'volunteer' if not provided
  user_role := COALESCE(new.raw_user_meta_data->>'role', 'volunteer');
  
  -- Parse date of birth if provided (format: YYYY-MM-DD)
  BEGIN
    user_dob := (new.raw_user_meta_data->>'dob')::DATE;
  EXCEPTION WHEN OTHERS THEN
    user_dob := NULL;
  END;
  
  -- Insert user record with all metadata
  INSERT INTO public.users (
    id, 
    email, 
    full_name, 
    role,
    phone_number,
    country_code,
    date_of_birth
  )
  VALUES (
    new.id, 
    new.email, 
    new.raw_user_meta_data->>'full_name',
    user_role,
    new.raw_user_meta_data->>'phone_number',
    COALESCE(new.raw_user_meta_data->>'country_code', '+91'),
    user_dob
  );
  
  RETURN new;
EXCEPTION WHEN OTHERS THEN
  -- Log error but don't fail the auth.users insert
  RAISE WARNING 'Error creating user in public.users: %', SQLERRM;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to automatically create user entry on signup
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
