-- CGE Lounge Mobile App — Database Schema
-- Run this in Supabase SQL Editor (supabase.com/dashboard → SQL Editor)

-- ═══════════════════════════════════════════════════════
-- PROFILES (extends Supabase auth.users)
-- ═══════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL DEFAULT '',
  phone TEXT,
  avatar_url TEXT,
  gamertag TEXT UNIQUE,
  bio TEXT,
  favourite_game TEXT,
  points INTEGER DEFAULT 0,
  wins INTEGER DEFAULT 0,
  losses INTEGER DEFAULT 0,
  team_id INTEGER,
  follower_count INTEGER DEFAULT 0,
  following_count INTEGER DEFAULT 0,
  tournament_count INTEGER DEFAULT 0,
  achievement_count INTEGER DEFAULT 0,
  total_listings INTEGER DEFAULT 0,
  total_sales INTEGER DEFAULT 0,
  total_swaps INTEGER DEFAULT 0,
  avg_rating DOUBLE PRECISION DEFAULT 0,
  rating_count INTEGER DEFAULT 0,
  trust_level TEXT DEFAULT 'new' CHECK (trust_level IN ('new', 'verified', 'trusted', 'power')),
  fcm_token TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, full_name, gamertag)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    NEW.raw_user_meta_data->>'gamertag'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ═══════════════════════════════════════════════════════
-- BOOKINGS
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
  status TEXT NOT NULL DEFAULT 'confirmed' CHECK (status IN ('confirmed', 'cancelled', 'completed')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════
-- MARKETPLACE LISTINGS
-- ═══════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS marketplace_listings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL,
  condition TEXT NOT NULL,
  listing_type TEXT NOT NULL DEFAULT 'swap' CHECK (listing_type IN ('swap', 'sell', 'swap_or_sell')),
  images TEXT[] DEFAULT '{}',
  swap_for_tags TEXT[] DEFAULT '{}',
  buyout_price INTEGER,
  views_count INTEGER DEFAULT 0,
  saves_count INTEGER DEFAULT 0,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'sold', 'swapped', 'archived')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Saved listings (many-to-many)
CREATE TABLE IF NOT EXISTS saved_listings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  listing_id UUID NOT NULL REFERENCES marketplace_listings(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, listing_id)
);

-- Swap proposals
CREATE TABLE IF NOT EXISTS swap_proposals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id UUID NOT NULL REFERENCES marketplace_listings(id) ON DELETE CASCADE,
  proposer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  offered_listing_id UUID REFERENCES marketplace_listings(id),
  message TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════
-- TOURNAMENTS
-- ═══════════════════════════════════════════════════════
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
  status TEXT DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'completed', 'cancelled')),
  rules TEXT,
  description TEXT,
  stream_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tournament registrations
CREATE TABLE IF NOT EXISTS tournament_registrations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_id INTEGER NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  checked_in BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(tournament_id, user_id)
);

-- ═══════════════════════════════════════════════════════
-- COMMUNITY POSTS
-- ═══════════════════════════════════════════════════════
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

-- Post likes
CREATE TABLE IF NOT EXISTS post_likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

-- Post comments
CREATE TABLE IF NOT EXISTS post_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Post bookmarks
CREATE TABLE IF NOT EXISTS post_bookmarks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

-- ═══════════════════════════════════════════════════════
-- CONVERSATIONS & MESSAGES
-- ═══════════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════════
-- EVENTS
-- ═══════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS events (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  type TEXT NOT NULL DEFAULT 'party' CHECK (type IN ('party', 'special', 'demo', 'package')),
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

-- ═══════════════════════════════════════════════════════
-- REVIEWS
-- ═══════════════════════════════════════════════════════
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
-- ROW LEVEL SECURITY (RLS)
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

-- Profiles: anyone can read, owners can update
CREATE POLICY "profiles_select" ON profiles FOR SELECT USING (true);
CREATE POLICY "profiles_update" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Bookings: users see their own
CREATE POLICY "bookings_select" ON bookings FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "bookings_insert" ON bookings FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "bookings_update" ON bookings FOR UPDATE USING (auth.uid() = user_id);

-- Marketplace: anyone can read, owners can manage
CREATE POLICY "listings_select" ON marketplace_listings FOR SELECT USING (true);
CREATE POLICY "listings_insert" ON marketplace_listings FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "listings_update" ON marketplace_listings FOR UPDATE USING (auth.uid() = user_id);

-- Saved listings: users manage their own
CREATE POLICY "saved_select" ON saved_listings FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "saved_insert" ON saved_listings FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "saved_delete" ON saved_listings FOR DELETE USING (auth.uid() = user_id);

-- Swap proposals: participants can see
CREATE POLICY "proposals_select" ON swap_proposals FOR SELECT USING (true);
CREATE POLICY "proposals_insert" ON swap_proposals FOR INSERT WITH CHECK (auth.uid() = proposer_id);

-- Tournaments: anyone can read
CREATE POLICY "tournaments_select" ON tournaments FOR SELECT USING (true);

-- Tournament registrations: authenticated users
CREATE POLICY "registrations_select" ON tournament_registrations FOR SELECT USING (true);
CREATE POLICY "registrations_insert" ON tournament_registrations FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Community posts: anyone can read, authors can manage
CREATE POLICY "posts_select" ON community_posts FOR SELECT USING (true);
CREATE POLICY "posts_insert" ON community_posts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "posts_update" ON community_posts FOR UPDATE USING (auth.uid() = user_id);

-- Post interactions: authenticated users
CREATE POLICY "likes_select" ON post_likes FOR SELECT USING (true);
CREATE POLICY "likes_insert" ON post_likes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "likes_delete" ON post_likes FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "comments_select" ON post_comments FOR SELECT USING (true);
CREATE POLICY "comments_insert" ON post_comments FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "bookmarks_select" ON post_bookmarks FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "bookmarks_insert" ON post_bookmarks FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "bookmarks_delete" ON post_bookmarks FOR DELETE USING (auth.uid() = user_id);

-- Conversations: participants only
CREATE POLICY "conversations_select" ON conversations FOR SELECT
  USING (auth.uid() = participant_one OR auth.uid() = participant_two);
CREATE POLICY "conversations_insert" ON conversations FOR INSERT
  WITH CHECK (auth.uid() = participant_one OR auth.uid() = participant_two);

-- Messages: conversation participants
CREATE POLICY "messages_select" ON messages FOR SELECT USING (true);
CREATE POLICY "messages_insert" ON messages FOR INSERT WITH CHECK (auth.uid() = sender_id);
CREATE POLICY "messages_update" ON messages FOR UPDATE USING (true);

-- Events: anyone can read
CREATE POLICY "events_select" ON events FOR SELECT USING (true);

-- Event registrations: authenticated users
CREATE POLICY "event_reg_select" ON event_registrations FOR SELECT USING (true);
CREATE POLICY "event_reg_insert" ON event_registrations FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "event_reg_delete" ON event_registrations FOR DELETE USING (auth.uid() = user_id);

-- Reviews: anyone can read, authenticated can write
CREATE POLICY "reviews_select" ON reviews FOR SELECT USING (true);
CREATE POLICY "reviews_insert" ON reviews FOR INSERT WITH CHECK (auth.uid() = reviewer_id);

-- ═══════════════════════════════════════════════════════
-- INDEXES
-- ═══════════════════════════════════════════════════════
CREATE INDEX IF NOT EXISTS idx_bookings_user ON bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_date ON bookings(booking_date);
CREATE INDEX IF NOT EXISTS idx_listings_user ON marketplace_listings(user_id);
CREATE INDEX IF NOT EXISTS idx_listings_category ON marketplace_listings(category);
CREATE INDEX IF NOT EXISTS idx_listings_status ON marketplace_listings(status);
CREATE INDEX IF NOT EXISTS idx_posts_user ON community_posts(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_topic ON community_posts(topic);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_reviews_seller ON reviews(seller_id);

-- ═══════════════════════════════════════════════════════
-- REALTIME (enable for live features)
-- ═══════════════════════════════════════════════════════
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE community_posts;
