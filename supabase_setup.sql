-- ==============================================================================
-- MASTER SUPABASE DATABASE SETUP FOR SAIFEDDINE BOUMAZA TRADING PLATFORM
-- Project: kbioxkoifvyivhkzbxke
-- Controls: Messages, All 14 Packages & Tiers, Wallets, Rates, & Contact Info
-- ==============================================================================

-- 1. MESSAGES TABLE (Receives every inquiry submitted on the website)
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    message TEXT NOT NULL,
    status TEXT DEFAULT 'new'
);

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public insert to messages" ON public.messages;
CREATE POLICY "Allow public insert to messages"
ON public.messages FOR INSERT TO anon, authenticated
WITH CHECK (true);

DROP POLICY IF EXISTS "Allow authenticated read messages" ON public.messages;
CREATE POLICY "Allow authenticated read messages"
ON public.messages FOR SELECT TO authenticated
USING (true);


-- 2. OFFERS TABLE (Controls EVERY price, package, deal, and subscription tier)
CREATE TABLE IF NOT EXISTS public.offers (
    id TEXT PRIMARY KEY,
    category TEXT NOT NULL,
    title TEXT NOT NULL,
    amount NUMERIC,
    price_usdt NUMERIC NOT NULL,
    original_price_usdt NUMERIC,
    discount_badge TEXT,
    validity TEXT,
    is_active BOOLEAN DEFAULT true,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.offers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read offers" ON public.offers;
CREATE POLICY "Allow public read offers"
ON public.offers FOR SELECT TO anon, authenticated
USING (true);

DROP POLICY IF EXISTS "Allow authenticated manage offers" ON public.offers;
CREATE POLICY "Allow authenticated manage offers"
ON public.offers FOR ALL TO authenticated
USING (true);


-- 3. SETTINGS TABLE (Controls Deposit Wallets, Calculator Rates, Telegram, Email)
CREATE TABLE IF NOT EXISTS public.settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    description TEXT,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read settings" ON public.settings;
CREATE POLICY "Allow public read settings"
ON public.settings FOR SELECT TO anon, authenticated
USING (true);

DROP POLICY IF EXISTS "Allow authenticated manage settings" ON public.settings;
CREATE POLICY "Allow authenticated manage settings"
ON public.settings FOR ALL TO authenticated
USING (true);


-- ==============================================================================
-- 4. INSERT ALL OFFERS, PACKAGES, RATES & WALLETS
-- ==============================================================================

-- All 14 Packages, Deals & Tiers:
INSERT INTO public.offers (id, category, title, amount, price_usdt, original_price_usdt, discount_badge, validity, is_active)
VALUES
    -- Flash Deals (Limited Time)
    ('flash_deal_1', 'flash_deal', 'Limited Deal #1', 80000, 100, 500, '80% OFF', '24H VALIDITY', true),
    ('flash_deal_2', 'flash_deal', 'Limited Deal #2', 8000, 30, 45, '30% OFF', '24H VALIDITY', true),

    -- 24 Hours Packages
    ('pack_24h_1k', 'pack_24h', 'Starter 1K · 24H', 1000, 10, 15, '', '24 Hours', true),
    ('pack_24h_100k', 'pack_24h', 'Pro 100K · 24H', 100000, 800, 1000, 'Popular', '24 Hours', true),
    ('pack_24h_1m', 'pack_24h', 'Whale 1M · 24H', 1000000, 1500, 2000, '', '24 Hours', true),

    -- 3 Days Packages
    ('pack_3d_1k', 'pack_3d', 'Starter 1K · 3 Days', 1000, 50, 65, '', '3 Days', true),
    ('pack_3d_100k', 'pack_3d', 'Pro 100K · 3 Days', 100000, 2000, 2500, 'Recommended', '3 Days', true),
    ('pack_3d_1m', 'pack_3d', 'Whale 1M · 3 Days', 1000000, 3800, 4500, '', '3 Days', true),

    -- 1 Week Packages
    ('pack_1w_1k', 'pack_1w', 'Starter 1K · 1 Week', 1000, 120, 150, '', '1 Week', true),
    ('pack_1w_100k', 'pack_1w', 'Pro 100K · 1 Week', 100000, 4000, 5000, 'Enterprise', '1 Week', true),
    ('pack_1w_1m', 'pack_1w', 'Whale 1M · 1 Week', 1000000, 7500, 9000, '', '1 Week', true),

    -- NewsX AI Subscriptions
    ('newsx_standard', 'newsx', 'NewsX AI Standard', 0, 15, 25, 'Standard', '1 Month', true),
    ('newsx_pro', 'newsx', 'NewsX AI Pro', 0, 25, 45, 'Popular', '1 Month', true),
    ('newsx_ultimate', 'newsx', 'NewsX AI Ultimate', 0, 50, 90, 'Elite', '1 Month', true)
ON CONFLICT (id) DO UPDATE SET
    price_usdt = EXCLUDED.price_usdt,
    original_price_usdt = EXCLUDED.original_price_usdt,
    discount_badge = EXCLUDED.discount_badge,
    amount = EXCLUDED.amount,
    title = EXCLUDED.title,
    updated_at = timezone('utc'::text, now());

-- Global Site Settings:
INSERT INTO public.settings (key, value, description)
VALUES
    ('wallet_bep20', '0x41f8a3a3a841cb3305bf1ebabe4ede7169a55bce', 'Official BEP20 Binance Smart Chain deposit wallet'),
    ('wallet_trc20', 'TEznkT5SKzYNHNe3wDEwfrxLpAq9HYA9sP', 'Official TRC20 Tron Network deposit wallet'),
    ('calc_rate_24h', '10', 'USDT cost per 1,000 Flash for 24h validity'),
    ('calc_rate_3d', '50', 'USDT cost per 1,000 Flash for 3d validity'),
    ('calc_rate_1w', '120', 'USDT cost per 1,000 Flash for 1w validity'),
    ('telegram_handle', '@HNTSB15', 'Official Telegram handle for contact & TX verification'),
    ('support_email', 'saifeddine.jskyst15@gmail.com', 'Official inquiry contact email')
ON CONFLICT (key) DO UPDATE SET
    value = EXCLUDED.value,
    updated_at = timezone('utc'::text, now());
