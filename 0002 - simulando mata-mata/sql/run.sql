.mode list
.headers off

-- preparacao
create or replace table memory.params as
select
10000 as qtd_multiversos,  -- quantos multiversos? 
500 as pausa_ms            -- pausa entre rodadas
;
.read "sql/setup.sql"

-- rodando 16 avos de final
.read "sql/loop.sql"

-- rodando oitavas de final
.read "sql/loop.sql"

-- rodando quartas de final
.read "sql/loop.sql"

-- rodando semifinais
.read "sql/loop.sql"

-- rodando final
.read "sql/loop.sql"

-- gerando reports
.read "sql/reports.sql"
