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
    preferred_platform TEXT DEFAULT 'Telegram',
    client_handle TEXT,
    direct_link TEXT,
    inquiry_topic TEXT,
    client_message TEXT NOT NULL,
    status TEXT DEFAULT 'New Message'
);

-- Ensure columns exist if table was already created earlier
ALTER TABLE public.client_messages ADD COLUMN IF NOT EXISTS preferred_platform TEXT DEFAULT 'Telegram';
ALTER TABLE public.client_messages ADD COLUMN IF NOT EXISTS client_handle TEXT;
ALTER TABLE public.client_messages ADD COLUMN IF NOT EXISTS direct_link TEXT;
ALTER TABLE public.client_messages ADD COLUMN IF NOT EXISTS inquiry_topic TEXT;

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
    ('support_email', 'saifeddine.jskyst15@gmail.com', 'Your official contact email'),
    ('whatsapp_number', '+213697114385', 'Your official WhatsApp phone number for client chat and leads'),
    ('telegram_bot_token', '8314044654:AAH6vijP6_P89z9btSTjtXQ0WWXtLevyHVY', 'Official Telegram Bot Token (@saif_leads_bot) for real-time lead alerts'),
    ('telegram_chat_id', '5513814495', 'Your personal Telegram Chat ID (@HNTSB15) where bot sends instant lead alerts'),
    ('instagram_profile', 'https://www.instagram.com/oo._.saifeddine._.oo/', 'Your official Instagram profile URL'),
    ('x_profile', 'https://x.com/seifeddin06', 'Your official X / Twitter profile URL')
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

-- 🛡️ Deduplicate existing rows (keeps only the first visit time for each IP address):
DELETE FROM public.website_visitors a
USING public.website_visitors b
WHERE a.ip_address = b.ip_address
  AND a.ip_address IS NOT NULL
  AND a.ip_address != 'Direct Visitor'
  AND a.visit_time > b.visit_time;

-- 🔒 Enforce UNIQUE IP address so subsequent visits never insert duplicates into Supabase:
CREATE UNIQUE INDEX IF NOT EXISTS website_visitors_unique_ip 
ON public.website_visitors (ip_address) 
WHERE ip_address IS NOT NULL AND ip_address != 'Direct Visitor';

DROP POLICY IF EXISTS "Allow public insert to website_visitors" ON public.website_visitors;
CREATE POLICY "Allow public insert to website_visitors"
ON public.website_visitors FOR INSERT TO anon, authenticated
WITH CHECK (true);

DROP POLICY IF EXISTS "Allow authenticated read website_visitors" ON public.website_visitors;
CREATE POLICY "Allow authenticated read website_visitors"
ON public.website_visitors FOR SELECT TO authenticated
USING (true);


-- ------------------------------------------------------------------------------
-- ⭐ TABLE 5: client_reviews (آراء وتقييمات العملاء والمستثمرين)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.client_reviews (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    client_name TEXT NOT NULL,
    client_country TEXT DEFAULT 'DZ',
    rating INT DEFAULT 5,
    service_type TEXT NOT NULL, -- 'managed', 'flash', 'signals', 'indicators'
    review_text TEXT NOT NULL,
    review_text_en TEXT,
    profit_stat TEXT, -- e.g. '+42.8% ROI (5 Months)', '80K Flash Delivered'
    is_verified BOOLEAN DEFAULT true,
    is_active BOOLEAN DEFAULT true
);

ALTER TABLE public.client_reviews ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public insert client_reviews" ON public.client_reviews;
CREATE POLICY "Allow public insert client_reviews"
ON public.client_reviews FOR INSERT TO anon, authenticated
WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public read client_reviews" ON public.client_reviews;
CREATE POLICY "Allow public read client_reviews"
ON public.client_reviews FOR SELECT TO anon, authenticated
USING (is_active = true);

DROP POLICY IF EXISTS "Allow authenticated manage client_reviews" ON public.client_reviews;
CREATE POLICY "Allow authenticated manage client_reviews"
ON public.client_reviews FOR ALL TO authenticated
USING (true);

-- Initial default verified reviews:
INSERT INTO public.client_reviews (client_name, client_country, rating, service_type, review_text, review_text_en, profit_stat, is_verified, is_active)
VALUES
    ('Tariq B.', 'الجزائر 🇩🇿', 5, 'managed', 'بدأت مع سيف الدين بمحفظة تجريبية ثم قمت برفع رأس المال. الالتزام بإدارة المخاطر ووقف الخسارة لا مثيل له، لا مغامرات ولا عشوائية، تقارير أسبوعية تفصيلية واحترافية عالية جداً.', 'Started with Saifeddine on a test portfolio then scaled my capital. The risk management and stop-loss discipline are second to none—zero reckless gambling. Detailed weekly reports and immense professionalism.', '+42.8% ROI (5 أشهر)', true, true),
    ('Faisal Al-Otaibi', 'السعودية 🇸🇦', 5, 'signals', 'أفضل قناة توصيات دخلت فيها من 3 سنوات. نقاط الدخول دقيقة جداً مع وقف خسارة صغير وأهداف محددة. قناة سيف الدين أنقذت حسابي من الخسائر المتراكمة وعوضت رأس مالي.', 'Hands down the best signal channel I have joined in 3 years. Precision entry points, tight stop-losses, and well-defined targets. Saifeddine VIP channel turned my losses into consistent profits.', 'Winrate 86% على الذهب XAUUSD', true, true),
    ('Karim Mansouri', 'فرنسا 🇫🇷', 5, 'flash', 'خدمة فائقة السرعة ودعم استثنائي عبر التيليجرام. تم تأكيد المعاملة على نود خاص في أقل من 3 دقائق. رقي واحترافية غير مسبوقة، أنصح بالتعامل معه بشدة!', 'Super fast service and exceptional support on Telegram. Transaction confirmed on a private blockchain node in under 3 minutes. Truly elite professionalism, highly recommended!', '80,000 Flash USDT · تسليم في 3 دقائق', true, true),
    ('Omar Al-Shammari', 'الإمارات 🇦🇪', 5, 'managed', 'الشفافية هي الرقم 1 عند الأخ سيف الدين. حسابي في Exness مربوط مباشرة وأرى كل صفقة تفتح وتغلق في نفس اللحظة مع الالتزام الصارم بنسبة 1-2% ريسك لكل صفقة.', 'Transparency is unmatched with brother Saifeddine. My Exness account is linked directly; I watch every trade open and close in real-time with strict 1-2% risk discipline per trade.', 'سحب أرباح شهري منتظم', true, true),
    ('David Henderson', 'بريطانيا 🇬🇧', 5, 'indicators', 'مؤشر MT5 المخصص لكسر التقلبات يعمل بكفاءة استثنائية وبدون أي إعادة رسم (Zero Repaint). تعليمات التثبيت واضحة والتسليم فوري على نظام ويندوز.', 'The custom MT5 volatility break indicator works flawlessly without repainting. Clean setup instructions and instant delivery on Windows. Excellent quantitative coding.', 'MT5 Indicator · 0 Repaint', true, true),
    ('Youssef Benali', 'المغرب 🇲🇦', 5, 'flash', 'تعامل راقٍ وسرعة استجابة على الواتساب. الباقة وصلت كاملة ومطابقة للمواصفات والشرح كان واضحاً خطوة بخطوة. استمر يا سيف الدين أنت فخر للشباب العربي.', 'Classy communication and rapid response on WhatsApp. The package was delivered completely as described with clear step-by-step guidance. True professional.', '100K Package · دعم فني مستمر', true, true)
ON CONFLICT DO NOTHING;



