-- CGE Lounge Mobile App — SAFE Migration
-- Only creates tables/policies that don't already exist
-- Run in Supabase SQL Editor

-- ═══════════════════════════════════════════════════════
-- First, drop any conflicting policies (ignore errors)
-- ═══════════════════════════════════════════════════════
DO $$ BEGIN
  -- Drop policies that might conflict
  EXECUTE 'DROP POLICY IF EXISTS "profiles_select" ON profiles';
  EXECUTE 'DROP POLICY IF EXISTS "profiles_update" ON profiles';
  EXECUTE 'DROP POLICY IF EXISTS "bookings_select" ON bookings';
  EXECUTE 'DROP POLICY IF EXISTS "bookings_insert" ON bookings';
  EXECUTE 'DROP POLICY IF EXISTS "bookings_update" ON bookings';
  EXECUTE 'DROP POLICY IF EXISTS "listings_select" ON marketplace_listings';
  EXECUTE 'DROP POLICY IF EXISTS "listings_insert" ON marketplace_listings';
  EXECUTE 'DROP POLICY IF EXISTS "listings_update" ON marketplace_listings';
  EXECUTE 'DROP POLICY IF EXISTS "saved_select" ON saved_listings';
  EXECUTE 'DROP POLICY IF EXISTS "saved_insert" ON saved_listings';
  EXECUTE 'DROP POLICY IF EXISTS "saved_delete" ON saved_listings';
  EXECUTE 'DROP POLICY IF EXISTS "proposals_select" ON swap_proposals';
  EXECUTE 'DROP POLICY IF EXISTS "proposals_insert" ON swap_proposals';
  EXECUTE 'DROP POLICY IF EXISTS "tournaments_select" ON tournaments';
  EXECUTE 'DROP POLICY IF EXISTS "registrations_select" ON tournament_registrations';
  EXECUTE 'DROP POLICY IF EXISTS "registrations_insert" ON tournament_registrations';
  EXECUTE 'DROP POLICY IF EXISTS "posts_select" ON community_posts';
  EXECUTE 'DROP POLICY IF EXISTS "posts_insert" ON community_posts';
  EXECUTE 'DROP POLICY IF EXISTS "posts_update" ON community_posts';
  EXECUTE 'DROP POLICY IF EXISTS "likes_select" ON post_likes';
  EXECUTE 'DROP POLICY IF EXISTS "likes_insert" ON post_likes';
  EXECUTE 'DROP POLICY IF EXISTS "likes_delete" ON post_likes';
  EXECUTE 'DROP POLICY IF EXISTS "comments_select" ON post_comments';
  EXECUTE 'DROP POLICY IF EXISTS "comments_insert" ON post_comments';
  EXECUTE 'DROP POLICY IF EXISTS "bookmarks_select" ON post_bookmarks';
  EXECUTE 'DROP POLICY IF EXISTS "bookmarks_insert" ON post_bookmarks';
  EXECUTE 'DROP POLICY IF EXISTS "bookmarks_delete" ON post_bookmarks';
  EXECUTE 'DROP POLICY IF EXISTS "conversations_select" ON conversations';
  EXECUTE 'DROP POLICY IF EXISTS "conversations_insert" ON conversations';
  EXECUTE 'DROP POLICY IF EXISTS "messages_select" ON messages';
  EXECUTE 'DROP POLICY IF EXISTS "messages_insert" ON messages';
  EXECUTE 'DROP POLICY IF EXISTS "messages_update" ON messages';
  EXECUTE 'DROP POLICY IF EXISTS "events_select" ON events';
  EXECUTE 'DROP POLICY IF EXISTS "event_reg_select" ON event_registrations';
  EXECUTE 'DROP POLICY IF EXISTS "event_reg_insert" ON event_registrations';
  EXECUTE 'DROP POLICY IF EXISTS "event_reg_delete" ON event_registrations';
  EXECUTE 'DROP POLICY IF EXISTS "reviews_select" ON reviews';
  EXECUTE 'DROP POLICY IF EXISTS "reviews_insert" ON reviews';
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- ═══════════════════════════════════════════════════════
-- ADD MISSING COLUMNS TO EXISTING TABLES
-- ═══════════════════════════════════════════════════════

-- Add user_id to marketplace_listings if it doesn't exist
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'marketplace_listings' AND column_name = 'user_id') THEN
    -- Check if creator_id exists and rename it
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'marketplace_listings' AND column_name = 'creator_id') THEN
      ALTER TABLE marketplace_listings RENAME COLUMN creator_id TO user_id;
    ELSE
      ALTER TABLE marketplace_listings ADD COLUMN user_id UUID REFERENCES profiles(id);
    END IF;
  END IF;
END $$;

-- Add missing columns to profiles
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'fcm_token') THEN
    ALTER TABLE profiles ADD COLUMN fcm_token TEXT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'trust_level') THEN
    ALTER TABLE profiles ADD COLUMN trust_level TEXT DEFAULT 'new';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'total_listings') THEN
    ALTER TABLE profiles ADD COLUMN total_listings INTEGER DEFAULT 0;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'total_sales') THEN
    ALTER TABLE profiles ADD COLUMN total_sales INTEGER DEFAULT 0;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'total_swaps') THEN
    ALTER TABLE profiles ADD COLUMN total_swaps INTEGER DEFAULT 0;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'avg_rating') THEN
    ALTER TABLE profiles ADD COLUMN avg_rating DOUBLE PRECISION DEFAULT 0;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'rating_count') THEN
    ALTER TABLE profiles ADD COLUMN rating_count INTEGER DEFAULT 0;
  END IF;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- ═══════════════════════════════════════════════════════
-- CREATE TABLES THAT DON'T EXIST YET
-- ═══════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  zone_id TEXT NOT NULL,
  game_name TEXT NOT NULL,
  booking_date DATE NOT NULL,
  time_slot TEXT NOT NULL,
  duration INTEGER NOT NULL DEFAULT 1,
  drinks JSONB DEFAULT '{}',
  session_total INTEGER NOT NULL DEFAULT 0,
  drinks_total INTEGER NOT NULL DEFAULT 0,
  total INTEGER NOT NULL DEFAULT 0,
  payment_method TEXT NOT NULL DEFAULT 'venue',
  payment_status TEXT NOT NULL DEFAULT 'pending',
  paystack_reference TEXT,
  pass_code TEXT,
  status TEXT NOT NULL DEFAULT 'confirmed',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS saved_listings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  listing_id UUID NOT NULL REFERENCES marketplace_listings(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, listing_id)
);

CREATE TABLE IF NOT EXISTS swap_proposals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id UUID NOT NULL REFERENCES marketplace_listings(id) ON DELETE CASCADE,
  proposer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  offered_listing_id UUID REFERENCES marketplace_listings(id),
  message TEXT,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tournaments (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  game TEXT NOT NULL,
  format TEXT NOT NULL DEFAULT 'single_elimination',
  platform TEXT NOT NULL DEFAULT 'PS5',
  max_players INTEGER NOT NULL DEFAULT 16,
  registered_count INTEGER DEFAULT 0,
  prize_pool INTEGER DEFAULT 0,
  entry_fee INTEGER DEFAULT 0,
  start_date TIMESTAMPTZ,
  status TEXT DEFAULT 'open',
  rules TEXT,
  description TEXT,
  stream_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tournament_registrations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_id INTEGER NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  checked_in BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(tournament_id, user_id)
);

CREATE TABLE IF NOT EXISTS community_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  topic TEXT,
  image_url TEXT,
  hashtags TEXT[] DEFAULT '{}',
  likes_count INTEGER DEFAULT 0,
  comments_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS post_likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

CREATE TABLE IF NOT EXISTS post_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS post_bookmarks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

CREATE TABLE IF NOT EXISTS conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  participant_one UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  participant_two UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  listing_id UUID REFERENCES marketplace_listings(id),
  listing_title TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  message_type TEXT DEFAULT 'text',
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS events (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  type TEXT NOT NULL DEFAULT 'party',
  date DATE NOT NULL,
  time TEXT,
  price INTEGER DEFAULT 0,
  capacity INTEGER DEFAULT 50,
  registered_count INTEGER DEFAULT 0,
  image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS event_registrations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id INTEGER NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(event_id, user_id)
);

CREATE TABLE IF NOT EXISTS reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reviewer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  seller_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  listing_id UUID REFERENCES marketplace_listings(id),
  rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment TEXT,
  type TEXT DEFAULT 'buyer_to_seller',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════
-- ENABLE RLS
-- ═══════════════════════════════════════════════════════
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE saved_listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE swap_proposals ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournaments ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournament_registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- ═══════════════════════════════════════════════════════
-- RLS POLICIES
-- ═══════════════════════════════════════════════════════

-- Profiles
CREATE POLICY "profiles_select" ON profiles FOR SELECT USING (true);
CREATE POLICY "profiles_update" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Bookings
CREATE POLICY "bookings_select" ON bookings FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "bookings_insert" ON bookings FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "bookings_update" ON bookings FOR UPDATE USING (auth.uid() = user_id);

-- Marketplace
CREATE POLICY "listings_select" ON marketplace_listings FOR SELECT USING (true);
CREATE POLICY "listings_insert" ON marketplace_listings FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "listings_update" ON marketplace_listings FOR UPDATE USING (auth.uid() = user_id);

-- Saved listings
CREATE POLICY "saved_select" ON saved_listings FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "saved_insert" ON saved_listings FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "saved_delete" ON saved_listings FOR DELETE USING (auth.uid() = user_id);

-- Swap proposals
CREATE POLICY "proposals_select" ON swap_proposals FOR SELECT USING (true);
CREATE POLICY "proposals_insert" ON swap_proposals FOR INSERT WITH CHECK (auth.uid() = proposer_id);

-- Tournaments
CREATE POLICY "tournaments_select" ON tournaments FOR SELECT USING (true);
CREATE POLICY "registrations_select" ON tournament_registrations FOR SELECT USING (true);
CREATE POLICY "registrations_insert" ON tournament_registrations FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Community
CREATE POLICY "posts_select" ON community_posts FOR SELECT USING (true);
CREATE POLICY "posts_insert" ON community_posts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "posts_update" ON community_posts FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "likes_select" ON post_likes FOR SELECT USING (true);
CREATE POLICY "likes_insert" ON post_likes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "likes_delete" ON post_likes FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "comments_select" ON post_comments FOR SELECT USING (true);
CREATE POLICY "comments_insert" ON post_comments FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "bookmarks_select" ON post_bookmarks FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "bookmarks_insert" ON post_bookmarks FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "bookmarks_delete" ON post_bookmarks FOR DELETE USING (auth.uid() = user_id);

-- Conversations & Messages
CREATE POLICY "conversations_select" ON conversations FOR SELECT
  USING (auth.uid() = participant_one OR auth.uid() = participant_two);
CREATE POLICY "conversations_insert" ON conversations FOR INSERT
  WITH CHECK (auth.uid() = participant_one OR auth.uid() = participant_two);

CREATE POLICY "messages_select" ON messages FOR SELECT USING (true);
CREATE POLICY "messages_insert" ON messages FOR INSERT WITH CHECK (auth.uid() = sender_id);
CREATE POLICY "messages_update" ON messages FOR UPDATE USING (true);

-- Events
CREATE POLICY "events_select" ON events FOR SELECT USING (true);
CREATE POLICY "event_reg_select" ON event_registrations FOR SELECT USING (true);
CREATE POLICY "event_reg_insert" ON event_registrations FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "event_reg_delete" ON event_registrations FOR DELETE USING (auth.uid() = user_id);

-- Reviews
CREATE POLICY "reviews_select" ON reviews FOR SELECT USING (true);
CREATE POLICY "reviews_insert" ON reviews FOR INSERT WITH CHECK (auth.uid() = reviewer_id);

-- ═══════════════════════════════════════════════════════
-- INDEXES
-- ═══════════════════════════════════════════════════════
CREATE INDEX IF NOT EXISTS idx_bookings_user ON bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_date ON bookings(booking_date);
CREATE INDEX IF NOT EXISTS idx_listings_user ON marketplace_listings(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_user ON community_posts(user_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_reviews_seller ON reviews(seller_id);

-- ═══════════════════════════════════════════════════════
-- REALTIME
-- ═══════════════════════════════════════════════════════
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE messages;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE community_posts;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- Auto-create profile on signup (if trigger doesn't exist)
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, full_name, gamertag)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    NEW.raw_user_meta_data->>'gamertag'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
