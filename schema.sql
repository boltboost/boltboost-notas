-- =============================================
-- BOLTBOOST NOTAS — Schema SQL v1.0.0
-- Correr no Supabase SQL Editor
-- =============================================

-- Tabela de pastas (suporta hierarquia infinita via parent_id)
CREATE TABLE IF NOT EXISTS folders (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name        TEXT NOT NULL,
  parent_id   UUID REFERENCES folders(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Tabela de notas
CREATE TABLE IF NOT EXISTS notes (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id         UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  folder_id       UUID REFERENCES folders(id) ON DELETE SET NULL,
  title           TEXT NOT NULL,
  description     TEXT,
  priority        TEXT DEFAULT 'media' CHECK (priority IN ('alta', 'media', 'baixa')),
  reminder_at     TIMESTAMPTZ,
  reminder_sent   BOOLEAN DEFAULT FALSE,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Row Level Security (RLS) — cada user só vê as suas notas
ALTER TABLE folders ENABLE ROW LEVEL SECURITY;
ALTER TABLE notes   ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_folders" ON folders FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "user_notes"   ON notes   FOR ALL USING (auth.uid() = user_id);

-- Trigger para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER notes_updated_at
  BEFORE UPDATE ON notes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();