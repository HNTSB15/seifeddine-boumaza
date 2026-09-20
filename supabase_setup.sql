-- ==============================================================================
-- 🌟 COMPLETE & CLEAN SUPABASE DATABASE ARCHITECTURE FOR SAIFEDDINE BOUMAZA
-- Project: kbioxkoifvyivhkzbxke
-- Description: Zero-Friction Setup with NO MANUAL "id" FIELDS ANYWHERE.
--              You NEVER need to enter or change an "id" when inserting rows!
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 🧹 STEP 1: CLEAN UP ALL OBSOLETE & OLD DATA (حذف جميع البيانات والجداول القديمة)
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS public.website_visitors CASCADE;
DROP TABLE IF EXISTS public.client_messages CASCADE;
DROP TABLE IF EXISTS public.client_reviews CASCADE;
DROP TABLE IF EXISTS public.payout_records CASCADE;
DROP TABLE IF EXISTS public.website_prices CASCADE;
DROP TABLE IF EXISTS public.website_settings CASCADE;
DROP TABLE IF EXISTS public.messages CASCADE;
DROP TABLE IF EXISTS public.settings CASCADE;
DROP TABLE IF EXISTS public.offers CASCADE;

-- ------------------------------------------------------------------------------
-- ⚙️ TABLE 1: website_settings (إعدادات الموقع، الإحصائيات، والروابط)
-- 💡 لا يوجد عمود "id" نهائياً! المفتاح هو اسم الإعداد مباشرة كملف إكسل مريح.
-- ------------------------------------------------------------------------------
CREATE TABLE public.website_settings (
    setting_name TEXT PRIMARY KEY,
    current_value TEXT NOT NULL,
    description_ar TEXT,
    category TEXT DEFAULT 'عام',
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.website_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read website_settings" ON public.website_settings;
DROP POLICY IF EXISTS "Allow authenticated manage website_settings" ON public.website_settings;
DROP POLICY IF EXISTS "Allow full access website_settings" ON public.website_settings;
CREATE POLICY "Allow full access website_settings"
ON public.website_settings FOR ALL TO anon, authenticated
USING (true) WITH CHECK (true);

-- البيانات الأولية لموقعك (يمكنك تعديل أي رقم أو نص منها مباشرة في Supabase):
INSERT INTO public.website_settings (setting_name, current_value, description_ar, category)
VALUES
    -- إحصائيات الأداء والتداول:
    ('stat_win_rate', '88%', 'نسبة نجاح الصفقات والتوصيات (Win Rate)', 'إحصائيات التداول'),
    ('stat_avg_return', '45%', 'متوسط العائد الاستثماري (Avg Return)', 'إحصائيات التداول'),
    ('stat_managed_capital', '$100K+', 'حجم رؤوس الأموال المدارة (Managed Capital)', 'إحصائيات التداول'),
    ('stat_years_exp', '5+', 'سنوات الخبرة في أسواق المال (Years Experience)', 'إحصائيات التداول'),
    ('stat_tracked_months', '12+', 'أشهر الأداء والنتائج الموثقة (Months Tracked)', 'إحصائيات التداول'),
    ('stat_community_traders', '500+', 'عدد المتداولين وأعضاء المجتمع (Community)', 'إحصائيات التداول'),
    
    -- الواجهة الرئيسية والشريط العلوي:
    ('hero_badge_text', 'متصل الآن · متاح لقبول محافظ جديدة للإدارة', 'النص الترحيبي بجانب النقطة الخضراء في أعلى الموقع', 'الواجهة الرئيسية'),
    ('hero_role', 'Forex Trading Expert', 'المسمى الوظيفي أسفل الاسم في الهيدر', 'الواجهة الرئيسية'),
    ('hero_tagline', 'Professional forex and cryptocurrency trading manager focused on transparent reporting, disciplined risk management, and strategic execution across active markets. Fast execution, trusted strategies, and expert support.', 'الوصف التعريفي المكتوب في واجهة الموقع', 'الواجهة الرئيسية'),
    
    -- قنوات التواصل والروابط الرسمية:
    ('telegram_username', '@HNTSB15', 'معرف حساب تيليجرام الرسمي', 'روابط التواصل'),
    ('telegram_channel', 'https://t.me/HNTSB15', 'رابط قناة تيليجرام الرسمية أو الشات المباشر', 'روابط التواصل'),
    ('whatsapp_number', '+213697114385', 'رقم الواتساب مع الرمز الدولي للشات المباشر', 'روابط التواصل'),
    ('support_email', 'saifeddine.jskyst15@gmail.com', 'البريد الإلكتروني الرسمي للاستفسارات', 'روابط التواصل'),
    ('instagram_profile', 'https://www.instagram.com/oo._.saifeddine._.oo/', 'رابط حساب انستغرام الرسمي', 'روابط التواصل'),
    ('x_profile', 'https://x.com/seifeddin06', 'رابط حساب منصة X (تويتر) الرسمي', 'روابط التواصل'),
    
    -- محافظ الإيداع والدفع بالعملات الرقمية:
    ('bep20_deposit_wallet', '0x41f8a3a3a841cb3305bf1ebabe4ede7169a55bce', 'عنوان محفظة USDT (BEP20 - Binance Smart Chain)', 'المحافظ الرقمية'),
    ('trc20_deposit_wallet', 'TEznkT5SKzYNHNe3wDEwfrxLpAq9HYA9sP', 'عنوان محفظة USDT (TRC20 - Tron)', 'المحافظ الرقمية'),
    
    -- شريط الإعلانات الترويجي أعلى الموقع:
    ('announcement_banner_text', '', 'نص الشريط الإعلاني في أعلى الموقع (اتركه فارغاً لإخفائه)', 'شريط الإعلانات'),
    ('announcement_banner_active', 'false', 'تفعيل (true) أو إيقاف (false) الشريط الإعلاني', 'شريط الإعلانات'),

    -- نبذة عني والاستراتيجية (About Me & Bio Paragraphs):
    ('about_p1', 'I''m <b>Saifeddine Boumaza</b> — a professional trading manager with specialized expertise in forex and cryptocurrency markets. I provide structured account management with transparent reporting, disciplined risk management, and strategic execution across active financial markets.', 'الفقرة الأولى في قسم About Me', 'نبذة عني'),
    ('about_p2', 'With over <b>5+ years</b> of hands-on experience across technical analysis, fundamental macro factors, chart patterns, and behavioral trading psychology, I help investors navigate volatility while aggressively defending downside risk through position sizing, strict stop-loss rules, and drawdown control.', 'الفقرة الثانية في قسم About Me', 'نبذة عني'),
    ('about_p3', 'I develop proprietary trading systems and provide real-time <b>VIP Trading Signals</b> for Gold (XAUUSD), major forex pairs (EUR/USD, GBP/USD), US indices (US30, Nasdaq), and high-liquidity crypto futures (BTC, ETH). In addition, I build custom <b>MT4 & MT5 indicators</b> on Windows for traders demanding automated alert precision.', 'الفقرة الثالثة في قسم About Me', 'نبذة عني'),

    -- شروط إدارة الحسابات ونسبة الأرباح:
    ('managed_min_capital', '$1,000+ USD ($100 for live trial)', 'الحد الأدنى لرأس مال إدارة الحسابات', 'إدارة المحافظ'),
    ('managed_profit_split', '50% / 50% Profit Share', 'نسبة تقاسم الأرباح الشهرية', 'إدارة المحافظ'),
    ('managed_drawdown_limit', '< 8.5% Maximum Drawdown', 'أقصى نسبة هبوط مسموح بها', 'إدارة المحافظ'),
    ('managed_supported_brokers', 'Exness, IC Markets, XM, Pepperstone', 'شركات الوساطة والبروكرز المدعومة', 'إدارة المحافظ'),

    -- خدمات التوصيات والمنصات:
    ('signals_vip_schedule', '2 - 5 High-Probability Trades Daily', 'جدول وتفاصيل توصيات VIP اليومية', 'توصيات VIP'),
    ('newsx_platform_link', '#newsx', 'رابط منصة NewsX AI المباشر', 'المنصات والأدوات'),
    ('tradingview_profile', 'https://www.tradingview.com/u/seifeddin06/', 'رابط حساب TradingView الرسمي', 'روابط التواصل'),
    ('youtube_channel', '', 'رابط قناة اليوتيوب الرسمية', 'روابط التواصل'),
    ('binance_pay_id', '441672878', 'معرف Binance Pay ID', 'المحافظ الرقمية'),
    ('footer_copyright', '© Saifeddine Boumaza - Forex & Crypto Trading Manager - All rights reserved', 'نص حقوق الملكية في الفوتر', 'الواجهة الرئيسية')
ON CONFLICT (setting_name) DO UPDATE SET
    current_value = EXCLUDED.current_value,
    description_ar = EXCLUDED.description_ar,
    category = EXCLUDED.category,
    updated_at = timezone('utc'::text, now());


-- ------------------------------------------------------------------------------
-- 🏷️ TABLE 2: website_prices (باقات وخدمات التداول والأسعار)
-- 💡 لا يوجد عمود "id" نهائياً! المفتاح هو كود الباقة (item_key).
-- ------------------------------------------------------------------------------
CREATE TABLE public.website_prices (
    item_key TEXT PRIMARY KEY,
    item_name TEXT DEFAULT '',
    current_price NUMERIC NOT NULL,
    old_price NUMERIC DEFAULT 0,
    discount_tag TEXT DEFAULT '',
    duration TEXT DEFAULT '1 Month',
    simple_guide TEXT DEFAULT '',
    is_active BOOLEAN DEFAULT true,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.website_prices ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read website_prices" ON public.website_prices;
DROP POLICY IF EXISTS "Allow authenticated manage website_prices" ON public.website_prices;
DROP POLICY IF EXISTS "Allow full access website_prices" ON public.website_prices;
CREATE POLICY "Allow full access website_prices"
ON public.website_prices FOR ALL TO anon, authenticated
USING (true) WITH CHECK (true);

INSERT INTO public.website_prices (item_key, item_name, current_price, old_price, discount_tag, duration, simple_guide, is_active)
VALUES
    ('newsx_standard', 'NewsX AI Standard Monthly', 15, 25, 'Standard', '1 Month', 'اشتراك شهري في منصة NewsX AI للتحليل الآلي', true),
    ('newsx_pro', 'NewsX AI Pro VIP Monthly', 25, 45, 'Popular', '1 Month', 'باقة NewsX AI الاحترافية مع تنبيهات تيليجرام الفورية', true),
    ('newsx_ultimate', 'NewsX AI Ultimate Master', 50, 90, 'Elite', '1 Month', 'الباقة الشاملة مع متابعة وتوجيه مباشر 1-on-1', true),
    ('account_management', 'Institutional Account Management', 0, 0, '50/50 Split', 'Ongoing', 'إدارة حسابات التداول بنظام تقاسم الأرباح 50/50', true),
    ('vip_gold_signals', 'VIP Gold & Forex Daily Signals', 49, 99, '50% OFF', '1 Month', 'توصيات VIP اليومية على الذهب والعملات مع أهداف محددة', true),
    ('mt5_indicator', 'Proprietary MT5 Volatility Indicator', 199, 350, 'Lifetime', 'Lifetime License', 'حزمة مؤشرات MT4/MT5 للويندوز بترخيص دائم مدى الحياة', true)
ON CONFLICT (item_key) DO UPDATE SET
    item_name = EXCLUDED.item_name,
    current_price = EXCLUDED.current_price,
    old_price = EXCLUDED.old_price,
    discount_tag = EXCLUDED.discount_tag,
    duration = EXCLUDED.duration,
    simple_guide = EXCLUDED.simple_guide,
    updated_at = timezone('utc'::text, now());


-- ------------------------------------------------------------------------------
-- ⭐ TABLE 3: client_reviews (آراء وتقييمات العملاء والمستثمرين)
-- 💡 الـ id يتولد تلقائياً 100% من السيرفر، لن يُطلب منك كتابته إطلاقاً!
-- ------------------------------------------------------------------------------
CREATE TABLE public.client_reviews (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    client_name TEXT NOT NULL,
    client_country TEXT DEFAULT 'الجزائر 🇩🇿',
    rating INT DEFAULT 5,
    service_type TEXT DEFAULT 'managed', -- 'managed', 'newsx', 'signals', 'indicators'
    review_text TEXT NOT NULL,
    review_text_en TEXT,
    profit_stat TEXT DEFAULT '',
    is_verified BOOLEAN DEFAULT true,
    is_active BOOLEAN DEFAULT true
);

ALTER TABLE public.client_reviews ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public insert client_reviews" ON public.client_reviews;
DROP POLICY IF EXISTS "Allow public read client_reviews" ON public.client_reviews;
DROP POLICY IF EXISTS "Allow authenticated manage client_reviews" ON public.client_reviews;
DROP POLICY IF EXISTS "Allow full access client_reviews" ON public.client_reviews;
CREATE POLICY "Allow full access client_reviews"
ON public.client_reviews FOR ALL TO anon, authenticated
USING (true) WITH CHECK (true);

INSERT INTO public.client_reviews (client_name, client_country, rating, service_type, review_text, review_text_en, profit_stat, is_verified, is_active)
VALUES
    ('Tariq B.', 'الجزائر 🇩🇿', 5, 'managed', 'بدأت مع سيف الدين بمحفظة تجريبية ثم قمت برفع رأس المال. الالتزام بإدارة المخاطر ووقف الخسارة لا مثيل له، لا مغامرات ولا عشوائية، تقارير أسبوعية تفصيلية واحترافية عالية جداً.', 'Started with Saifeddine on a test portfolio then scaled my capital. The risk management and stop-loss discipline are second to none—zero reckless gambling. Detailed weekly reports and immense professionalism.', '+42.8% ROI (5 أشهر)', true, true),
    ('Faisal Al-Otaibi', 'السعودية 🇸🇦', 5, 'signals', 'أفضل قناة توصيات دخلت فيها من 3 سنوات. نقاط الدخول دقيقة جداً مع وقف خسارة صغير وأهداف محددة. قناة سيف الدين أنقذت حسابي من الخسائر المتراكمة وعوضت رأس مالي.', 'Hands down the best signal channel I have joined in 3 years. Precision entry points, tight stop-losses, and well-defined targets. Saifeddine VIP channel turned my losses into consistent profits.', 'Winrate 86% على الذهب XAUUSD', true, true),
    ('Karim Mansouri', 'فرنسا 🇫🇷', 5, 'newsx', 'منصة NewsX AI رائعة جداً في وقت صدور أخبار الـ CPI والـ NFP. الترجيح المسبق لاتجاه الذهب وفر علي ساعات من التحليل وساعدني في تحقيق صفقات موفقة جداً.', 'The NewsX AI platform is exceptional during high-impact CPI and NFP news releases. Pre-release directional bias on Gold saved me hours of analysis and led to outstanding trade executions.', 'اشتراك NewsX AI · ترجيح دقيق', true, true),
    ('Omar Al-Shammari', 'الإمارات 🇦🇪', 5, 'managed', 'الشفافية هي الرقم 1 عند الأخ سيف الدين. حسابي في Exness مربوط مباشرة وأرى كل صفقة تفتح وتغلق في نفس اللحظة مع الالتزام الصارم بنسبة 1-2% ريسك لكل صفقة.', 'Transparency is unmatched with brother Saifeddine. My Exness account is linked directly; I watch every trade open and close in real-time with strict 1-2% risk discipline per trade.', 'سحب أرباح شهري منتظم', true, true),
    ('David Henderson', 'بريطانيا 🇬🇧', 5, 'indicators', 'مؤشر MT5 المخصص لكسر التقلبات يعمل بكفاءة استثنائية وبدون أي إعادة رسم (Zero Repaint). تعليمات التثبيت واضحة والتسليم فوري على نظام ويندوز.', 'The custom MT5 volatility break indicator works flawlessly without repainting. Clean setup instructions and instant delivery on Windows. Excellent quantitative coding.', 'MT5 Indicator · 0 Repaint', true, true),
    ('Youssef Benali', 'المغرب 🇲🇦', 5, 'newsx', 'تطبيق NewsX AI سريع وخفيف على الهاتف، إشعارات الأخبار تصل قبل حركة السوق بثوانٍ حاسمة. احترافية عالية ودعم فني متواصل من الأخ سيف الدين.', 'The NewsX AI app is lightning fast on mobile. Push alerts arrive right before explosive market volatility. True quantitative edge and continuous support from Saifeddine.', 'ترجيح الذهب XAUUSD · تنبيهات', true, true);


-- ------------------------------------------------------------------------------
-- 💵 TABLE 4: payout_records (سحوبات Exness الموثقة وإثباتات الأرباح)
-- 💡 الـ id يتولد تلقائياً 100% من السيرفر. لإضافة سحب جديد، فقط اكتب المبلغ والتاريخ!
-- ------------------------------------------------------------------------------
CREATE TABLE public.payout_records (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    type TEXT DEFAULT 'double', -- 'double' (Exness + Binance) or 'ledger' (Exness direct)
    amount TEXT NOT NULL,
    date TEXT NOT NULL,
    date_ar TEXT DEFAULT '',
    account TEXT DEFAULT 'ex 256505258',
    invoice TEXT DEFAULT '',
    binance_order TEXT DEFAULT '',
    binance_time TEXT DEFAULT '',
    speed TEXT DEFAULT '1m 42s',
    speed_ar TEXT DEFAULT 'دقيقة و 42 ثانية',
    exness_img TEXT DEFAULT '',
    binance_img TEXT DEFAULT '',
    is_verified BOOLEAN DEFAULT true,
    is_active BOOLEAN DEFAULT true,
    display_order INT DEFAULT 0
);

ALTER TABLE public.payout_records ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read payout_records" ON public.payout_records;
DROP POLICY IF EXISTS "Allow authenticated manage payout_records" ON public.payout_records;
DROP POLICY IF EXISTS "Allow full access payout_records" ON public.payout_records;
CREATE POLICY "Allow full access payout_records"
ON public.payout_records FOR ALL TO anon, authenticated
USING (true) WITH CHECK (true);

INSERT INTO public.payout_records (type, amount, date, date_ar, account, invoice, binance_order, binance_time, speed, speed_ar, exness_img, binance_img, is_verified, is_active, display_order)
VALUES
    ('double', '$3,150.51 USD', '11 Sep 2026, 14:11', '11 سبتمبر 2026 - 14:11', 'ex 256505258', '807876734982', '441672878207459329', '14:12:42 UTC', '1m 42s', 'دقيقة و 42 ثانية', 'proofs/payout-1-exness.png', 'proofs/payout-1-binance.png', true, true, 1),
    ('double', '$1,555.00 USD', '19 May 2026, 12:35', '19 مايو 2026 - 12:35', 'ex 256511737', '676651208710', '441672878207459329', '12:37:42 UTC', '2m 42s', 'دقيقتين و 42 ثانية', 'proofs/payout-2-exness.png', 'proofs/payout-2-binance.png', true, true, 2),
    ('double', '$1,026.00 USD', '18 May 2026, 13:36', '18 مايو 2026 - 13:36', 'ex 256505258', '675581050886', '441672878207459329', '13:37:42 UTC', '1m 42s', 'دقيقة و 42 ثانية', 'proofs/payout-3-exness.png', 'proofs/payout-3-binance.png', true, true, 3),
    ('double', '$723.00 USD', '18 May 2026, 02:13', '18 مايو 2026 - 02:13', 'ex 256505258', '674909700102', '441672878207459329', '02:14:42 UTC', '1m 42s', 'دقيقة و 42 ثانية', 'proofs/payout-4-exness.png', 'proofs/payout-4-binance.png', true, true, 4),
    ('double', '$1,522.00 USD', '15 May 2026, 15:54', '15 مايو 2026 - 15:54', 'ex 256497449', '673924100102', '441672878207459329', '15:56:42 UTC', '2m 42s', 'دقيقتين و 42 ثانية', 'proofs/payout-5-exness.png', 'proofs/payout-5-binance.png', true, true, 5),
    ('double', '$1,129.00 USD', '15 May 2026, 14:33', '15 مايو 2026 - 14:33', 'ex 256497174', '673759997958', '441672878207459329', '14:33:42 UTC', 'Instant (< 1m)', 'فوري (أقل من دقيقة)', 'proofs/payout-6-exness.png', 'proofs/payout-6-binance.png', true, true, 6),
    ('ledger', '$4,278.81 USD', '28 Aug 2026, 16:24', '28 أغسطس 2026 - 16:24', 'ex 256505258', '788728934406', '', '', 'Instant', 'فوري', 'proofs/payout-7-exness.png', '', true, true, 7),
    ('ledger', '$1,500.00 USD', '12 Aug 2026, 14:42', '12 أغسطس 2026 - 14:42', 'ex 256698295', '768002146310', '', '', 'Instant', 'فوري', 'proofs/payout-8-exness.png', '', true, true, 8),
    ('ledger', '$500.00 USD', '22 May 2026, 14:08', '22 مايو 2026 - 14:08', 'ex 256516464', '680002113542', '', '', 'Instant', 'فوري', 'proofs/payout-9-exness.png', '', true, true, 9),
    ('ledger', '$575.00 USD', '21 May 2026, 12:00', '21 مايو 2026 - 12:00', 'ex 256516464', '678917492742', '', '', 'Instant', 'فوري', 'proofs/payout-10-exness.png', '', true, true, 10);


-- ------------------------------------------------------------------------------
-- 📬 TABLE 5: client_messages (رسائل نموذج التواصل والاستفسارات المباشرة)
-- 💡 تُسجل كل رسالة يرسلها الزائر تلقائياً مع دولته ومدينته ونوع جهازه!
-- ------------------------------------------------------------------------------
CREATE TABLE public.client_messages (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    date_sent TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    client_name TEXT NOT NULL,
    client_email TEXT NOT NULL,
    preferred_platform TEXT DEFAULT 'Telegram',
    client_handle TEXT DEFAULT '',
    direct_link TEXT DEFAULT '',
    inquiry_topic TEXT DEFAULT 'General Inquiry',
    client_message TEXT NOT NULL,
    client_ip TEXT DEFAULT '',
    client_country TEXT DEFAULT '',
    client_city TEXT DEFAULT '',
    client_device TEXT DEFAULT '',
    status TEXT DEFAULT 'New Message'
);

ALTER TABLE public.client_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public insert to client_messages" ON public.client_messages;
DROP POLICY IF EXISTS "Allow authenticated read client_messages" ON public.client_messages;
DROP POLICY IF EXISTS "Allow authenticated manage client_messages" ON public.client_messages;
DROP POLICY IF EXISTS "Allow full access client_messages" ON public.client_messages;
CREATE POLICY "Allow full access client_messages"
ON public.client_messages FOR ALL TO anon, authenticated
USING (true) WITH CHECK (true);


-- ------------------------------------------------------------------------------
-- 🌍 TABLE 6: website_visitors (تتبع وتحليلات الزوار الشاملة والمفصلة)
-- 💡 تم تصميمه ليظهر لك كل شيء عن الزائر: الدولة، المدينة، الجهاز، النظام، والمتصفح.
--    ويتم تحديث عدد زياراته تلقائياً بدون تكرار الصفوف لنفس الآي بي!
-- ------------------------------------------------------------------------------
CREATE TABLE public.website_visitors (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_visit TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    last_seen TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    visit_count INT DEFAULT 1,
    ip_address TEXT UNIQUE,
    country TEXT,
    country_code TEXT,
    city TEXT,
    region TEXT,
    timezone TEXT,
    isp_provider TEXT,
    device_type TEXT,        -- 'Mobile', 'Desktop', 'Tablet'
    device_model TEXT,       -- 'Apple iPhone 15', 'Samsung Galaxy', 'Windows PC'
    operating_system TEXT,   -- 'iOS 17', 'Android 14', 'Windows 11'
    browser TEXT,            -- 'Chrome', 'Safari', 'Firefox'
    screen_size TEXT,        -- '393x852', '1920x1080'
    language TEXT,           -- 'ar-DZ', 'en-US'
    source_referrer TEXT,    -- 'Instagram', 'Twitter / X', 'Telegram', 'Direct'
    landing_page TEXT DEFAULT '/'
);

ALTER TABLE public.website_visitors ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public insert to website_visitors" ON public.website_visitors;
DROP POLICY IF EXISTS "Allow public update to website_visitors" ON public.website_visitors;
DROP POLICY IF EXISTS "Allow authenticated read website_visitors" ON public.website_visitors;
DROP POLICY IF EXISTS "Allow authenticated manage website_visitors" ON public.website_visitors;
DROP POLICY IF EXISTS "Allow full access website_visitors" ON public.website_visitors;
CREATE POLICY "Allow full access website_visitors"
ON public.website_visitors FOR ALL TO anon, authenticated
USING (true) WITH CHECK (true);

-- ==============================================================================
-- 🚀 تم الانتهاء بنجاح! 
-- انسخ هذا الكود بالكامل وضعه في Supabase SQL Editor ثم اضغط Run.
-- كل الجداول جاهزة الآن وتعمل بدون الحاجة لكتابة أو تعديل أي ID يدوياً!
-- ==============================================================================
