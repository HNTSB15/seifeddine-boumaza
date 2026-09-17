-- ==============================================================================
-- 🌟 CLEAR & SIMPLE SUPABASE DATABASE FOR SAIFEDDINE BOUMAZA
-- Project: kbioxkoifvyivhkzbxke
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 🧹 STEP 1: CONSOLIDATE & REMOVE OLD DUPLICATE TABLES
-- (Combines messages into client_messages, settings into website_settings, and removes old duplicates)
-- ------------------------------------------------------------------------------
DO $$
BEGIN
    -- If old 'messages' table exists, migrate any messages into client_messages first:
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'messages') THEN
        IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'client_messages') THEN
            INSERT INTO public.client_messages (client_name, client_email, client_message, date_sent)
            SELECT name, email, message, COALESCE(created_at, now())
            FROM public.messages
            ON CONFLICT DO NOTHING;
        END IF;
    END IF;
END $$;

-- Drop old duplicate tables so your dashboard has ONLY clean unified tables:
DROP TABLE IF EXISTS public.messages CASCADE;
DROP TABLE IF EXISTS public.settings CASCADE;
DROP TABLE IF EXISTS public.offers CASCADE;


-- ------------------------------------------------------------------------------
-- 📬 TABLE 1: client_messages (ONE SINGLE TABLE FOR ALL MESSAGES)
-- (Every message sent by a visitor on your website appears here)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.client_messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    date_sent TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    client_name TEXT NOT NULL,
    client_email TEXT NOT NULL,
    client_message TEXT NOT NULL,
    status TEXT DEFAULT 'New Message'
);

ALTER TABLE public.client_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public insert to client_messages" ON public.client_messages;
CREATE POLICY "Allow public insert to client_messages"
ON public.client_messages FOR INSERT TO anon, authenticated
WITH CHECK (true);

DROP POLICY IF EXISTS "Allow authenticated read client_messages" ON public.client_messages;
CREATE POLICY "Allow authenticated read client_messages"
ON public.client_messages FOR SELECT TO authenticated
USING (true);


-- ------------------------------------------------------------------------------
-- 🏷️ TABLE 2: website_prices
-- (Double-click "current_price" to change what customers pay on your website!)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.website_prices (
    item_key TEXT PRIMARY KEY,
    item_name TEXT NOT NULL,
    current_price NUMERIC NOT NULL,
    old_price NUMERIC,
    discount_tag TEXT,
    flash_usdt_amount NUMERIC,
    duration TEXT,
    simple_guide TEXT,
    is_active BOOLEAN DEFAULT true,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.website_prices ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read website_prices" ON public.website_prices;
CREATE POLICY "Allow public read website_prices"
ON public.website_prices FOR SELECT TO anon, authenticated
USING (true);

DROP POLICY IF EXISTS "Allow authenticated manage website_prices" ON public.website_prices;
CREATE POLICY "Allow authenticated manage website_prices"
ON public.website_prices FOR ALL TO authenticated
USING (true);


-- ------------------------------------------------------------------------------
-- ⚙️ TABLE 3: website_settings
-- (Controls your Crypto Wallets, Calculator Rates, and Telegram username)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.website_settings (
    setting_name TEXT PRIMARY KEY,
    current_value TEXT NOT NULL,
    what_it_does TEXT,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.website_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read website_settings" ON public.website_settings;
CREATE POLICY "Allow public read website_settings"
ON public.website_settings FOR SELECT TO anon, authenticated
USING (true);

DROP POLICY IF EXISTS "Allow authenticated manage website_settings" ON public.website_settings;
CREATE POLICY "Allow authenticated manage website_settings"
ON public.website_settings FOR ALL TO authenticated
USING (true);


-- ------------------------------------------------------------------------------
-- 📥 INSERT ALL 14 DEALS & PACKAGES WITH CLEAR NAMES:
-- ------------------------------------------------------------------------------
INSERT INTO public.website_prices (item_key, item_name, current_price, old_price, discount_tag, flash_usdt_amount, duration, simple_guide, is_active)
VALUES
    -- 🔥 FLASH SALE DEALS:
    ('flash_deal_1', '🔥 Limited Deal 1 (80,000 Flash)', 100, 500, '80% OFF', 80000, '24 Hours', 'Deal 1 box on your website: change current_price to change the deal', true),
    ('flash_deal_2', '⚡ Limited Deal 2 (8,000 Flash)', 30, 45, '30% OFF', 8000, '24 Hours', 'Deal 2 box on your website: change current_price to change the deal', true),

    -- ⏱️ 24 HOURS PACKAGES:
    ('package_24h_1k', 'Starter 1K · 24 Hours', 10, 15, '', 1000, '24 Hours', '1,000 Flash package in 24 Hours tab', true),
    ('package_24h_100k', 'Pro 100K · 24 Hours', 800, 1000, 'Popular', 100000, '24 Hours', '100,000 Flash package in 24 Hours tab', true),
    ('package_24h_1m', 'Whale 1M · 24 Hours', 1500, 2000, '', 1000000, '24 Hours', '1,000,000 Flash package in 24 Hours tab', true),

    -- 📅 3 DAYS PACKAGES:
    ('package_3days_1k', 'Starter 1K · 3 Days', 50, 65, '', 1000, '3 Days', '1,000 Flash package in 3 Days tab', true),
    ('package_3days_100k', 'Pro 100K · 3 Days', 2000, 2500, 'Recommended', 100000, '3 Days', '100,000 Flash package in 3 Days tab', true),
    ('package_3days_1m', 'Whale 1M · 3 Days', 3800, 4500, '', 1000000, '3 Days', '1,000,000 Flash package in 3 Days tab', true),

    -- 📆 1 WEEK PACKAGES:
    ('package_1week_1k', 'Starter 1K · 1 Week', 120, 150, '', 1000, '1 Week', '1,000 Flash package in 1 Week tab', true),
    ('package_1week_100k', 'Pro 100K · 1 Week', 4000, 5000, 'Enterprise', 100000, '1 Week', '100,000 Flash package in 1 Week tab', true),
    ('package_1week_1m', 'Whale 1M · 1 Week', 7500, 9000, '', 1000000, '1 Week', '1,000,000 Flash package in 1 Week tab', true),

    -- ⚡ NEWSX AI SUBSCRIPTION TIERS:
    ('newsx_standard', 'NewsX AI Standard Monthly', 15, 25, 'Standard', 0, '1 Month', 'NewsX Standard monthly subscription price', true),
    ('newsx_pro', 'NewsX AI Pro Monthly', 25, 45, 'Popular', 0, '1 Month', 'NewsX Pro VIP monthly subscription price', true),
    ('newsx_ultimate', 'NewsX AI Ultimate Monthly', 50, 90, 'Elite', 0, '1 Month', 'NewsX Ultimate Master monthly subscription price', true)
ON CONFLICT (item_key) DO UPDATE SET
    item_name = EXCLUDED.item_name,
    current_price = EXCLUDED.current_price,
    old_price = EXCLUDED.old_price,
    discount_tag = EXCLUDED.discount_tag,
    flash_usdt_amount = EXCLUDED.flash_usdt_amount,
    simple_guide = EXCLUDED.simple_guide,
    updated_at = timezone('utc'::text, now());


-- ------------------------------------------------------------------------------
-- ⚙️ INSERT SETTINGS (WALLETS & CALCULATOR RATES):
-- ------------------------------------------------------------------------------
INSERT INTO public.website_settings (setting_name, current_value, what_it_does)
VALUES
    ('bep20_deposit_wallet', '0x41f8a3a3a841cb3305bf1ebabe4ede7169a55bce', 'Your official BEP20 Binance Smart Chain wallet where clients send payments'),
    ('trc20_deposit_wallet', 'TEznkT5SKzYNHNe3wDEwfrxLpAq9HYA9sP', 'Your official TRC20 Tron wallet where clients send payments'),
    ('calculator_price_24h_per_1k', '10', 'USDT price for 1,000 Flash (24 Hours) in the custom calculator'),
    ('calculator_price_3days_per_1k', '50', 'USDT price for 1,000 Flash (3 Days) in the custom calculator'),
    ('calculator_price_1week_per_1k', '120', 'USDT price for 1,000 Flash (1 Week) in the custom calculator'),
    ('telegram_username', '@HNTSB15', 'Your official Telegram handle displayed across the website and payment desk'),
    ('support_email', 'saifeddine.jskyst15@gmail.com', 'Your official contact email')
ON CONFLICT (setting_name) DO UPDATE SET
    current_value = EXCLUDED.current_value,
    what_it_does = EXCLUDED.what_it_does,
    updated_at = timezone('utc'::text, now());


-- ------------------------------------------------------------------------------
-- 🌍 TABLE 4: website_visitors
-- (Tracks every visitor: IP address, Location, Phone Name, OS, Browser, Time)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.website_visitors (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    visit_time TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    ip_address TEXT,
    country TEXT,
    city TEXT,
    device_model TEXT,
    operating_system TEXT,
    browser TEXT,
    screen_size TEXT,
    language TEXT,
    source_referrer TEXT
);

ALTER TABLE public.website_visitors ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public insert to website_visitors" ON public.website_visitors;
CREATE POLICY "Allow public insert to website_visitors"
ON public.website_visitors FOR INSERT TO anon, authenticated
WITH CHECK (true);

DROP POLICY IF EXISTS "Allow authenticated read website_visitors" ON public.website_visitors;
CREATE POLICY "Allow authenticated read website_visitors"
ON public.website_visitors FOR SELECT TO authenticated
USING (true);


-- ------------------------------------------------------------------------------
-- 📊 TABLE 5: managed_trades
-- (Live Managed Account Results & Twitter Proofs. Insert a new row from your phone/dashboard and it appears at the front of your website!)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.managed_trades (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    published_date TEXT NOT NULL DEFAULT 'Today',
    badge_text TEXT NOT NULL DEFAULT 'RECORD PROFIT ⚡',
    badge_type TEXT NOT NULL DEFAULT 'neon', -- 'neon' or 'gold'
    deposit_amount TEXT NOT NULL DEFAULT '$100+',
    profit_amount TEXT NOT NULL DEFAULT '+$1,000',
    description TEXT NOT NULL,
    tags TEXT[] DEFAULT ARRAY['#Forex', '#Gold', '#Trading']::TEXT[],
    tweet_url TEXT DEFAULT 'https://x.com/seifeddin06',
    profit_split TEXT DEFAULT 'Profit Split: 50/50',
    images TEXT[] NOT NULL DEFAULT '{}'::TEXT[],
    is_active BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0
);

ALTER TABLE public.managed_trades ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read managed_trades" ON public.managed_trades;
CREATE POLICY "Allow public read managed_trades"
ON public.managed_trades FOR SELECT TO anon, authenticated
USING (true);

DROP POLICY IF EXISTS "Allow authenticated manage managed_trades" ON public.managed_trades;
CREATE POLICY "Allow authenticated manage managed_trades"
ON public.managed_trades FOR ALL TO authenticated
USING (true);

-- Insert current 4 Twitter trade records:
INSERT INTO public.managed_trades (sort_order, published_date, badge_text, badge_type, deposit_amount, profit_amount, description, tags, tweet_url, profit_split, images, is_active)
VALUES
(
    1,
    'Sep 16, 2026',
    'RECORD PROFIT ⚡',
    'neon',
    'Deposit: $430',
    '+$16,000',
    'MANAGING A NEW ACCOUNT — Live verified trading execution with disciplined drawdown control on Gold & Forex. Deposit: $430 ➡️ Net Profit: +$16,000.',
    ARRAY['#Gold', '#XAUUSD', '#Forex', '#ManagedAccount'],
    'https://x.com/seifeddin06/status/2100553514652983364',
    'Profit Split: 50/50',
    ARRAY[
        'https://pbs.twimg.com/media/HSaqRvdXsAE_gBX?format=jpg&name=large',
        'https://pbs.twimg.com/media/HSaqRvrXsAACCxJ?format=jpg&name=large',
        'https://pbs.twimg.com/media/HSaqRveXAAAOcYp?format=jpg&name=large',
        'https://pbs.twimg.com/media/HSaqRvcWYAEduzN?format=jpg&name=large'
    ],
    true
),
(
    2,
    'Sep 15, 2026',
    '11X RETURN 🎯',
    'gold',
    'Deposit: $500',
    '+$5,700',
    'MANAGING A NEW ACCOUNT — Account growth from $500 to $5,700 net profit through strict risk management and momentum trading on Gold (XAUUSD).',
    ARRAY['#Forex', '#XAUUSD', '#Trading', '#Profits'],
    'https://x.com/seifeddin06/status/2100186065541685374',
    'Profit Split: 50/50',
    ARRAY[
        'https://pbs.twimg.com/media/HSVcFq1W0AAWx0G?format=jpg&name=large',
        'https://pbs.twimg.com/media/HSVcFqzWAAAxI20?format=jpg&name=large'
    ],
    true
),
(
    3,
    'Sep 14, 2026',
    '15X RETURN 🚀',
    'neon',
    'Deposit: $100',
    '+$1,500',
    'Small account scalability proof: $100 starting deposit grown to $1,500 net profit with strict stop-loss rules on Gold (XAUUSD).',
    ARRAY['#Gold', '#XAUUSD', '#ForexSignals', '#Growth'],
    'https://x.com/seifeddin06/status/2099978339200962981',
    'Profit Split: 50/50',
    ARRAY[
        'https://pbs.twimg.com/media/HSSe1-HWkAAavQ2?format=jpg&name=large',
        'https://pbs.twimg.com/media/HSSe1-tXwAEBFsL?format=jpg&name=large',
        'https://pbs.twimg.com/media/HSSe17SWQAA1R6u?format=jpg&name=large',
        'https://pbs.twimg.com/media/HSSe17ZW8AAqO1h?format=jpg&name=large'
    ],
    true
),
(
    4,
    'Sep 13, 2026',
    'TIERS OPEN 💼',
    'gold',
    'Starting: $100+',
    '$500+ Max',
    'TRADING ACCOUNT MANAGEMENT TIERS: Available for $100+, $200+, $300+, $400+, $500+. Dedicated risk management on Gold (XAUUSD).',
    ARRAY['#Forex', '#Trading', '#Gold', '#AccountManagement'],
    'https://x.com/seifeddin06/status/2099508672397275183',
    'Telegram: @HNTSB15',
    ARRAY[
        'https://pbs.twimg.com/media/HSLx32aa8AEPunw?format=jpg&name=large',
        'https://pbs.twimg.com/media/HSLx32HXcAELU5b?format=jpg&name=large'
    ],
    true
);
