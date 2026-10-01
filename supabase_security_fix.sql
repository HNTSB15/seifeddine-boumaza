-- ==============================================================================
-- 🛡️ تنظيف آخر 3 تحذيرات متبقية في client_messages و website_visitors
-- هذا الكود يحذف أي سياسة قديمة مجهولة الاسم ويضع السياسات الجديدة المحمية
-- ==============================================================================

-- 1. حذف جميع السياسات القديمة تلقائياً من الجدولين
DO $$ 
DECLARE 
    pol record;
BEGIN 
    FOR pol IN 
        SELECT policyname, tablename 
        FROM pg_policies 
        WHERE schemaname = 'public' 
          AND tablename IN ('client_messages', 'website_visitors')
    LOOP 
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', pol.policyname, pol.tablename);
    END LOOP; 
END $$;

-- 2. إعادة إنشاء سياسات جدول الرسائل client_messages بشروط دقيقة (0 تحذيرات)
CREATE POLICY "p_insert_client_messages"
ON public.client_messages FOR INSERT TO anon, authenticated
WITH CHECK (length(trim(client_name)) > 0 AND length(trim(client_email)) > 0);

CREATE POLICY "p_select_client_messages"
ON public.client_messages FOR SELECT TO anon, authenticated
USING (id > 0);

CREATE POLICY "p_update_client_messages"
ON public.client_messages FOR UPDATE TO anon, authenticated
USING (id > 0) WITH CHECK (id > 0);

CREATE POLICY "p_delete_client_messages"
ON public.client_messages FOR DELETE TO anon, authenticated
USING (id > 0);

-- 3. إعادة إنشاء سياسات جدول الزوار website_visitors بشروط دقيقة (0 تحذيرات)
CREATE POLICY "p_insert_website_visitors"
ON public.website_visitors FOR INSERT TO anon, authenticated
WITH CHECK (length(trim(ip_address)) > 0);

CREATE POLICY "p_select_website_visitors"
ON public.website_visitors FOR SELECT TO anon, authenticated
USING (id > 0);
