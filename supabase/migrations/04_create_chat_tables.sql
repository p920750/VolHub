-- Create Chat Rooms Table
CREATE TABLE IF NOT EXISTS public.chat_rooms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT, -- Room name (for groups/communities)
    type TEXT NOT NULL CHECK (type IN ('single', 'group', 'community')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    metadata JSONB DEFAULT '{}'::JSONB
);

-- Create Chat Room Participants Table
CREATE TABLE IF NOT EXISTS public.chat_room_participants (
    room_id UUID REFERENCES public.chat_rooms(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    PRIMARY KEY (room_id, user_id)
);

-- Create Messages Table
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id UUID REFERENCES public.chat_rooms(id) ON DELETE CASCADE NOT NULL,
    sender_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    content TEXT NOT NULL,
    type TEXT DEFAULT 'text' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    is_read BOOLEAN DEFAULT FALSE
);

-- Enable RLS
ALTER TABLE public.chat_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_room_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Room Status Policies
-- Users can see rooms they are part of
CREATE POLICY "Users can see rooms they are part of" ON public.chat_rooms
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.chat_room_participants
            WHERE room_id = public.chat_rooms.id AND user_id = auth.uid()
        )
    );

-- Participants Policies
CREATE POLICY "Users can see participants of their rooms" ON public.chat_room_participants
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.chat_room_participants AS sub
            WHERE sub.room_id = public.chat_room_participants.room_id AND sub.user_id = auth.uid()
        )
    );

-- Message Policies
-- Users can see messages in rooms they are part of
CREATE POLICY "Users can read messages in their rooms" ON public.messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.chat_room_participants
            WHERE room_id = public.messages.room_id AND user_id = auth.uid()
        )
    );

-- Users can insert messages in rooms they are part of
CREATE POLICY "Users can send messages to their rooms" ON public.messages
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.chat_room_participants
            WHERE room_id = public.messages.room_id AND user_id = auth.uid()
        ) AND sender_id = auth.uid()
    );

-- Real-time setup (Add to publication)
-- Note: Realtime might need to be enabled for these tables in the dashboard or via SQL
-- ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_rooms, public.chat_room_participants, public.messages;
