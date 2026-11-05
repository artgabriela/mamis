-- =====================================================================
-- CASA DA MÃE — Controle de contas divididas
-- Rodar uma única vez no Supabase: SQL Editor > New query > colar > Run
-- As tabelas usam o prefixo cm_ para não conflitar com outros projetos
-- que já estejam no mesmo Supabase (ex.: Casa em Ordem).
-- =====================================================================

-- Pessoas que dividem a conta e o percentual padrão de cada uma
create table if not exists cm_pessoas (
  id     text primary key,
  nome   text not null,
  pct    numeric(6,2) not null default 0,
  cor    text,
  ordem  int default 0
);

-- Contas do mês (aluguel, gás, energia, internet, outras)
create table if not exists cm_contas (
  id          uuid primary key default gen_random_uuid(),
  mes         text not null,                -- competência, formato AAAA-MM
  categoria   text not null,                -- aluguel | gas | energia | internet | outra
  descricao   text,
  valor       numeric(12,2) not null,
  vencimento  date,
  paga        boolean not null default false,
  pago_por    text references cm_pessoas(id),
  pago_em     date,
  divisao     jsonb not null,               -- ex.: {"gabi":40,"matheus":40,"mae":20}
  criado_em   timestamptz default now()
);

-- Repasses (acerto da cota) e ajudas (valor extra, fora da divisão)
create table if not exists cm_lancamentos (
  id         uuid primary key default gen_random_uuid(),
  mes        text not null,                 -- mês de referência, AAAA-MM
  tipo       text not null check (tipo in ('repasse','ajuda')),
  de         text not null references cm_pessoas(id),
  para       text references cm_pessoas(id),
  valor      numeric(12,2) not null,
  data       date,
  obs        text,
  criado_em  timestamptz default now()
);

create index if not exists cm_contas_mes_idx      on cm_contas (mes);
create index if not exists cm_lancamentos_mes_idx on cm_lancamentos (mes);

-- Pessoas iniciais (os percentuais são ajustados depois, no próprio painel)
insert into cm_pessoas (id, nome, pct, cor, ordem) values
  ('gabi',    'Gabi',    33.33, '#B9657E', 1),
  ('matheus', 'Matheus', 33.33, '#4F7EA6', 2),
  ('mae',     'Mãe',     33.34, '#6C9867', 3)
on conflict (id) do nothing;

-- ---------------------------------------------------------------------
-- Acesso: liberado para a chave pública (anon), como em um painel
-- familiar simples. Quem tiver o link + a chave consegue ler e editar.
-- ---------------------------------------------------------------------
alter table cm_pessoas     enable row level security;
alter table cm_contas      enable row level security;
alter table cm_lancamentos enable row level security;

drop policy if exists cm_pessoas_all     on cm_pessoas;
drop policy if exists cm_contas_all      on cm_contas;
drop policy if exists cm_lancamentos_all on cm_lancamentos;

create policy cm_pessoas_all     on cm_pessoas     for all to anon using (true) with check (true);
create policy cm_contas_all      on cm_contas      for all to anon using (true) with check (true);
create policy cm_lancamentos_all on cm_lancamentos for all to anon using (true) with check (true);

-- Atualização em tempo real: quando um registra, os outros veem na hora
alter publication supabase_realtime add table cm_pessoas;
alter publication supabase_realtime add table cm_contas;
alter publication supabase_realtime add table cm_lancamentos;

-- ---------------------------------------------------------------------
-- ANEXOS (boleto/conta em PDF ou foto + comprovante de pagamento)
-- Os arquivos ficam no Storage, bucket privado "cm-arquivos".
-- O painel abre cada arquivo por um link temporário (assinado).
-- ---------------------------------------------------------------------
alter table cm_contas      add column if not exists boleto_path      text;
alter table cm_contas      add column if not exists comprovante_path text;
alter table cm_lancamentos add column if not exists comprovante_path text;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('cm-arquivos', 'cm-arquivos', false, 10485760,
        array['application/pdf','image/jpeg','image/png','image/webp','image/heic','image/heif'])
on conflict (id) do nothing;

drop policy if exists cm_arquivos_select on storage.objects;
drop policy if exists cm_arquivos_insert on storage.objects;
drop policy if exists cm_arquivos_update on storage.objects;
drop policy if exists cm_arquivos_delete on storage.objects;

create policy cm_arquivos_select on storage.objects for select to anon using (bucket_id = 'cm-arquivos');
create policy cm_arquivos_insert on storage.objects for insert to anon with check (bucket_id = 'cm-arquivos');
create policy cm_arquivos_update on storage.objects for update to anon using (bucket_id = 'cm-arquivos') with check (bucket_id = 'cm-arquivos');
create policy cm_arquivos_delete on storage.objects for delete to anon using (bucket_id = 'cm-arquivos');

-- ---------------------------------------------------------------------
-- LOGIN (celular + senha), aplicado depois do bloco acima.
-- Só usuários logados que estão em cm_membros acessam dados e arquivos.
-- Usuários, números e senhas são cadastrados à parte, direto no banco
-- (login interno <55DDDNUMERO>@mamis.app), e NÃO ficam neste arquivo.
-- ---------------------------------------------------------------------
create table if not exists public.cm_membros (
  telefone   text primary key,
  pessoa_id  text not null references public.cm_pessoas(id),
  user_id    uuid unique references auth.users(id) on delete set null,
  criado_em  timestamptz default now()
);
alter table public.cm_membros enable row level security;
create index if not exists cm_membros_pessoa_idx on public.cm_membros (pessoa_id);

create or replace function public.cm_e_membro()
returns boolean language sql stable security definer set search_path = ''
as $$ select exists (select 1 from public.cm_membros m where m.user_id = (select auth.uid())) $$;
revoke all on function public.cm_e_membro() from public, anon;
grant execute on function public.cm_e_membro() to authenticated;

drop policy if exists cm_membros_proprio on public.cm_membros;
create policy cm_membros_proprio on public.cm_membros for select to authenticated using (user_id = (select auth.uid()));

drop policy if exists cm_pessoas_all     on public.cm_pessoas;
drop policy if exists cm_contas_all      on public.cm_contas;
drop policy if exists cm_lancamentos_all on public.cm_lancamentos;
create policy cm_pessoas_all     on public.cm_pessoas     for all to authenticated using ((select public.cm_e_membro())) with check ((select public.cm_e_membro()));
create policy cm_contas_all      on public.cm_contas      for all to authenticated using ((select public.cm_e_membro())) with check ((select public.cm_e_membro()));
create policy cm_lancamentos_all on public.cm_lancamentos for all to authenticated using ((select public.cm_e_membro())) with check ((select public.cm_e_membro()));

drop policy if exists cm_arquivos_select on storage.objects;
drop policy if exists cm_arquivos_insert on storage.objects;
drop policy if exists cm_arquivos_update on storage.objects;
drop policy if exists cm_arquivos_delete on storage.objects;
create policy cm_arquivos_select on storage.objects for select to authenticated using (bucket_id = 'cm-arquivos' and (select public.cm_e_membro()));
create policy cm_arquivos_insert on storage.objects for insert to authenticated with check (bucket_id = 'cm-arquivos' and (select public.cm_e_membro()));
create policy cm_arquivos_update on storage.objects for update to authenticated using (bucket_id = 'cm-arquivos' and (select public.cm_e_membro())) with check (bucket_id = 'cm-arquivos' and (select public.cm_e_membro()));
create policy cm_arquivos_delete on storage.objects for delete to authenticated using (bucket_id = 'cm-arquivos' and (select public.cm_e_membro()));
