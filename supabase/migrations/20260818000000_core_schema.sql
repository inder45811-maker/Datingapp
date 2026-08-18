-- Enable Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- Domain Enums
CREATE TYPE gender_identity AS ENUM ('man', 'woman', 'non_binary', 'couple', 'trans', 'other');
CREATE TYPE relationship_desire AS ENUM ('monogamish', 'polyamorous', 'open_relationship', 'casual', 'curious', 'kink');
CREATE TYPE swipe_direction AS ENUM ('like', 'dislike', 'superlike');

-- Profiles Table
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT NOT NULL CHECK (char_length(display_name) >= 2),
    birthdate DATE NOT NULL CHECK (birthdate <= CURRENT_DATE - INTERVAL '18 years'),
    bio TEXT DEFAULT '',
    gender gender_identity NOT NULL,
    desires relationship_desire[] DEFAULT '{}',
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    photos TEXT[] DEFAULT '{}' CHECK (array_length(photos, 1) >= 1),
    private_photos TEXT[] DEFAULT '{}',
    linked_partner_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    is_incognito BOOLEAN DEFAULT FALSE,
    is_premium BOOLEAN DEFAULT FALSE,
    premium_expires_at TIMESTAMPTZ,
    is_available_soon BOOLEAN DEFAULT FALSE,
    available_until TIMESTAMPTZ,
    last_active TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_profiles_location ON public.profiles USING GIST (location);
CREATE INDEX idx_profiles_partner ON public.profiles(linked_partner_id);
CREATE INDEX idx_profiles_available_soon ON public.profiles (is_available_soon, available_until)
  WHERE is_available_soon = TRUE;

-- Swipes Ledger
CREATE TABLE public.swipes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    swiper_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    swiped_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    direction swipe_direction NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_swipes_pair UNIQUE(swiper_id, swiped_id)
);

CREATE INDEX idx_swipes_lookup ON public.swipes(swiper_id, swiped_id, direction);

-- Active Matches Table (Strict Ordering: user1_id < user2_id to eliminate duplication)
CREATE TABLE public.matches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user1_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    user2_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    is_group_match BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT user1_lower_than_user2 CHECK (user1_id < user2_id),
    CONSTRAINT unique_match_pair UNIQUE(user1_id, user2_id)
);

CREATE INDEX idx_matches_users ON public.matches(user1_id, user2_id);

-- Realtime Messaging
CREATE TABLE public.messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    match_id UUID NOT NULL REFERENCES public.matches(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL CHECK (char_length(content) > 0),
    media_url TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_messages_match_time ON public.messages(match_id, created_at DESC);

-- Safety: Blocks & Reports (Apple Guideline 1.2)
CREATE TABLE public.blocks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    blocker_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    blocked_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_block_pair UNIQUE(blocker_id, blocked_id)
);

CREATE TABLE public.reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    reported_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'investigating', 'resolved', 'dismissed')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Row Level Security (RLS) Policies
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.swipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY profiles_read ON public.profiles FOR SELECT USING (true);
CREATE POLICY profiles_update ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY profiles_insert ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY profiles_delete ON public.profiles FOR DELETE USING (auth.uid() = id);

CREATE POLICY swipes_insert ON public.swipes FOR INSERT WITH CHECK (auth.uid() = swiper_id);
CREATE POLICY swipes_select ON public.swipes FOR SELECT USING (auth.uid() = swiper_id);

CREATE POLICY matches_select ON public.matches FOR SELECT 
    USING (auth.uid() = user1_id OR auth.uid() = user2_id);

CREATE POLICY messages_select ON public.messages FOR SELECT 
    USING (EXISTS (
        SELECT 1 FROM public.matches m 
        WHERE m.id = messages.match_id AND (m.user1_id = auth.uid() OR m.user2_id = auth.uid())
    ));

CREATE POLICY messages_insert ON public.messages FOR INSERT 
    WITH CHECK (auth.uid() = sender_id);

CREATE POLICY messages_update ON public.messages FOR UPDATE 
    USING (EXISTS (
        SELECT 1 FROM public.matches m 
        WHERE m.id = messages.match_id AND (m.user1_id = auth.uid() OR m.user2_id = auth.uid())
    ));

CREATE POLICY blocks_all ON public.blocks FOR ALL USING (auth.uid() = blocker_id);
CREATE POLICY reports_insert ON public.reports FOR INSERT WITH CHECK (auth.uid() = reporter_id);
CREATE POLICY reports_select ON public.reports FOR SELECT USING (auth.uid() = reporter_id);

-- Stored Procedure: Optimized Spatial Discovery Algorithm
CREATE OR REPLACE FUNCTION get_nearby_deck(
    p_user_id UUID,
    p_user_lat DOUBLE PRECISION,
    p_user_long DOUBLE PRECISION,
    p_radius_meters DOUBLE PRECISION DEFAULT 80000,
    p_limit INT DEFAULT 30
)
RETURNS TABLE (
    id UUID,
    display_name TEXT,
    birthdate DATE,
    bio TEXT,
    gender gender_identity,
    desires relationship_desire[],
    photos TEXT[],
    distance_meters DOUBLE PRECISION,
    is_coupled BOOLEAN,
    partner_id UUID,
    partner_name TEXT,
    partner_photos TEXT[],
    is_available_soon BOOLEAN
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.display_name,
        p.birthdate,
        p.bio,
        p.gender,
        p.desires,
        p.photos,
        ST_Distance(p.location, ST_SetSRID(ST_MakePoint(p_user_long, p_user_lat), 4326)::geography) AS distance_meters,
        (p.linked_partner_id IS NOT NULL) AS is_coupled,
        p.linked_partner_id AS partner_id,
        partner.display_name AS partner_name,
        partner.photos AS partner_photos,
        (p.is_available_soon = TRUE AND (p.available_until IS NULL OR p.available_until > NOW())) AS is_available_soon
    FROM public.profiles p
    LEFT JOIN public.profiles partner ON p.linked_partner_id = partner.id
    WHERE p.id != p_user_id
      AND p.is_incognito = FALSE
      -- Exclude swiped targets
      AND NOT EXISTS (
          SELECT 1 FROM public.swipes s 
          WHERE s.swiper_id = p_user_id AND s.swiped_id = p.id
      )
      -- Exclude bidirectional blocked users
      AND NOT EXISTS (
          SELECT 1 FROM public.blocks b 
          WHERE (b.blocker_id = p_user_id AND b.blocked_id = p.id)
             OR (b.blocker_id = p.id AND b.blocked_id = p_user_id)
      )
      -- Geospatial Radius Condition
      AND ST_DWithin(p.location, ST_SetSRID(ST_MakePoint(p_user_long, p_user_lat), 4326)::geography, p_radius_meters)
    ORDER BY 
        (p.is_available_soon = TRUE AND (p.available_until IS NULL OR p.available_until > NOW())) DESC,
        distance_meters ASC
    LIMIT p_limit;
END;
$$;

-- Grant execute on discovery function to authenticated users
GRANT EXECUTE ON FUNCTION get_nearby_deck TO authenticated;
GRANT EXECUTE ON FUNCTION get_nearby_deck TO service_role;
