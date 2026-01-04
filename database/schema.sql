-- ============================================
-- BLOG SYSTEM AUTOMATION - DATABASE SCHEMA
-- Minerals Trading Daily
-- ============================================

-- ============================================
-- 1. CONTENT TABLES
-- ============================================

-- Posts principais do blog
CREATE TABLE IF NOT EXISTS content_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(200) NOT NULL,
  slug VARCHAR(200) UNIQUE,
  content TEXT NOT NULL,
  excerpt TEXT,
  author VARCHAR(100) DEFAULT 'Minerals Trading Daily',
  category VARCHAR(50),
  tags TEXT[], -- Array de tags
  source_url TEXT,
  source_hash VARCHAR(64) UNIQUE, -- Para deduplicacao
  status VARCHAR(20) DEFAULT 'draft'
    CHECK (status IN ('draft', 'approved', 'rejected', 'published', 'archived')),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Metadados do post (imagem, SEO, etc)
CREATE TABLE IF NOT EXISTS content_metadata (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID REFERENCES content_posts(id) ON DELETE CASCADE,
  featured_image_url TEXT,
  featured_image_alt TEXT,
  seo_title VARCHAR(70),
  seo_description VARCHAR(160),
  reading_time INT, -- minutos
  word_count INT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Controle de workflow/revisao
CREATE TABLE IF NOT EXISTS content_workflow (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID REFERENCES content_posts(id) ON DELETE CASCADE,
  stage VARCHAR(30) DEFAULT 'pending_review'
    CHECK (stage IN ('pending_review', 'in_review', 'feedback', 'approved', 'awaiting_image', 'published')),
  reviewer_notes TEXT,
  review_notes TEXT, -- Feedback do revisor
  telegram_message_id INTEGER,
  session_id VARCHAR(50),
  reviewed_at TIMESTAMPTZ,
  published_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- 2. IMAGE TABLES
-- ============================================

-- Imagens geradas para posts
CREATE TABLE IF NOT EXISTS post_images (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID REFERENCES content_posts(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  prompt TEXT, -- Prompt usado para gerar
  model VARCHAR(50), -- gemini, dall-e, etc
  status VARCHAR(20) DEFAULT 'pending'
    CHECK (status IN ('pending', 'approved', 'rejected', 'published')),
  telegram_message_id INTEGER,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- 3. SOCIAL MEDIA TABLES
-- ============================================

-- Sessoes de publicacao em redes sociais
CREATE TABLE IF NOT EXISTS social_media_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id VARCHAR(50) UNIQUE NOT NULL,
  post_id UUID REFERENCES content_posts(id) ON DELETE CASCADE,
  chat_id VARCHAR(50) NOT NULL,
  message_id INTEGER,

  -- Conteudo gerado
  twitter_content JSONB, -- {tweet1, tweet2, tweet3, tweet4}
  linkedin_content TEXT,
  instagram_content TEXT,

  -- Imagem do Twitter
  twitter_image_url TEXT,
  twitter_image_approved BOOLEAN DEFAULT false,

  -- Status por rede
  twitter_status VARCHAR(20) DEFAULT 'pending',
  linkedin_status VARCHAR(20) DEFAULT 'pending',
  instagram_status VARCHAR(20) DEFAULT 'pending',

  -- Resultados
  twitter_result JSONB,
  linkedin_result JSONB,
  instagram_result JSONB,

  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Historico de publicacoes sociais
CREATE TABLE IF NOT EXISTS published_social (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID REFERENCES content_posts(id) ON DELETE CASCADE,
  platform VARCHAR(20) NOT NULL CHECK (platform IN ('twitter', 'linkedin', 'instagram')),
  external_id TEXT, -- ID do post na plataforma
  url TEXT,
  content TEXT,
  image_url TEXT,
  published_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- 4. REVIEW TABLES
-- ============================================

-- Sessoes de revisao (Draft Review)
CREATE TABLE IF NOT EXISTS review_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id VARCHAR(50) UNIQUE NOT NULL,
  chat_id VARCHAR(50) NOT NULL,
  post_ids UUID[], -- Array de posts na sessao
  current_index INT DEFAULT 0,
  status VARCHAR(20) DEFAULT 'active'
    CHECK (status IN ('active', 'completed', 'expired')),
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Sessoes de edicao rapida (Quick Edit)
CREATE TABLE IF NOT EXISTS edit_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id VARCHAR(50) UNIQUE NOT NULL,
  post_id UUID REFERENCES content_posts(id) ON DELETE CASCADE,
  chat_id VARCHAR(50) NOT NULL,
  user_id VARCHAR(50),
  message_id INTEGER,
  edit_type VARCHAR(20) CHECK (edit_type IN ('title', 'tags', 'content')),
  stage VARCHAR(20) DEFAULT 'waiting_input'
    CHECK (stage IN ('waiting_input', 'preview', 'confirmed', 'cancelled', 'expired')),
  original_value TEXT,
  new_value TEXT,
  ai_processed BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  expires_at TIMESTAMPTZ
);

-- ============================================
-- 5. NEWSLETTER TABLES
-- ============================================

-- Historico de newsletters
CREATE TABLE IF NOT EXISTS newsletter_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subject VARCHAR(200) NOT NULL,
  content_html TEXT NOT NULL,
  summary TEXT,
  posts_included JSONB, -- [{id, title, url}]
  price_data JSONB, -- Precos Platts
  perplexity_context TEXT, -- Contexto de mercado
  ai_analysis JSONB, -- Resposta do AI Agent
  image_url TEXT,
  status VARCHAR(20) DEFAULT 'draft'
    CHECK (status IN ('draft', 'pending_approval', 'approved', 'sent', 'cancelled')),
  sent_at TIMESTAMPTZ,
  recipients_count INT,
  open_rate DECIMAL,
  click_rate DECIMAL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Sessoes de aprovacao de newsletter
CREATE TABLE IF NOT EXISTS newsletter_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id VARCHAR(50) UNIQUE NOT NULL,
  newsletter_id UUID REFERENCES newsletter_history(id) ON DELETE CASCADE,
  chat_id VARCHAR(50) NOT NULL,
  message_id INTEGER,
  stage VARCHAR(20) DEFAULT 'pending_content'
    CHECK (stage IN ('pending_content', 'pending_image', 'ready_to_send', 'sent', 'expired', 'cancelled')),
  content_approved BOOLEAN DEFAULT false,
  image_approved BOOLEAN DEFAULT false,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- 6. MARKET DATA TABLES
-- ============================================

-- Precos do minerio (Platts IODEX)
CREATE TABLE IF NOT EXISTS iron_ore_prices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  indicator VARCHAR(100) NOT NULL,
  value DECIMAL(10, 2) NOT NULL,
  unit VARCHAR(20) DEFAULT 'USD/dmt',
  date DATE NOT NULL,
  source VARCHAR(50) DEFAULT 'Platts',
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(indicator, date)
);

-- ============================================
-- 7. LOGGING TABLES
-- ============================================

-- Log de erros do sistema
CREATE TABLE IF NOT EXISTS error_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workflow_id VARCHAR(50),
  workflow_name VARCHAR(100),
  node_name VARCHAR(100),
  error_message TEXT,
  error_stack TEXT,
  execution_id VARCHAR(50),
  occurrence_count INT DEFAULT 1,
  first_seen_at TIMESTAMPTZ DEFAULT now(),
  last_seen_at TIMESTAMPTZ DEFAULT now(),
  resolved BOOLEAN DEFAULT false
);

-- Historico de publicacoes (WordPress)
CREATE TABLE IF NOT EXISTS published_content (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID REFERENCES content_posts(id) ON DELETE CASCADE,
  wordpress_id INTEGER,
  wordpress_url TEXT,
  featured_image_id INTEGER,
  published_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- 8. INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_content_posts_status ON content_posts(status);
CREATE INDEX IF NOT EXISTS idx_content_posts_created ON content_posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_content_workflow_stage ON content_workflow(stage);
CREATE INDEX IF NOT EXISTS idx_post_images_status ON post_images(status);
CREATE INDEX IF NOT EXISTS idx_social_sessions_status ON social_media_sessions(twitter_status);
CREATE INDEX IF NOT EXISTS idx_newsletter_status ON newsletter_history(status);
CREATE INDEX IF NOT EXISTS idx_iron_ore_prices_date ON iron_ore_prices(date DESC);

-- ============================================
-- 9. FUNCTIONS
-- ============================================

-- Funcao para limpar sessoes expiradas
CREATE OR REPLACE FUNCTION cleanup_expired_sessions()
RETURNS void AS $$
BEGIN
  -- Edit sessions
  UPDATE edit_sessions
  SET stage = 'expired', updated_at = now()
  WHERE stage = 'waiting_input'
    AND expires_at < now();

  -- Newsletter sessions
  UPDATE newsletter_sessions
  SET stage = 'expired', updated_at = now()
  WHERE stage IN ('pending_content', 'pending_image')
    AND expires_at < now();

  -- Review sessions
  UPDATE review_sessions
  SET status = 'expired'
  WHERE status = 'active'
    AND expires_at < now();
END;
$$ LANGUAGE plpgsql;

-- Trigger para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger em todas as tabelas relevantes
DO $$
DECLARE
  t text;
BEGIN
  FOR t IN
    SELECT table_name
    FROM information_schema.columns
    WHERE column_name = 'updated_at'
      AND table_schema = 'public'
  LOOP
    EXECUTE format('
      DROP TRIGGER IF EXISTS update_%I_updated_at ON %I;
      CREATE TRIGGER update_%I_updated_at
        BEFORE UPDATE ON %I
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at();
    ', t, t, t, t);
  END LOOP;
END;
$$;
