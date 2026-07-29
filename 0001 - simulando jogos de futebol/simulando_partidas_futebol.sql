ATTACH IF NOT EXISTS 'simulando_partidas.db' as sp;
use sp;

CREATE OR REPLACE TABLE sp.pais as
-- importa o CSV para dentro do DuckDB
SELECT *
FROM read_csv('in/pais.csv',
  delim = ';',
  header = true,
  columns = {
    'id': 'int',
    'nome': 'VARCHAR',
    'sigla': 'VARCHAR',
    'rank_atual_fifa': 'int',
    'pontos_atuais': 'float'
  }
);

create or replace table sp.versus as
-- calculos de forca dos dois times e preparacao para simulacao
with ids_times as (
    select
  -- pegar os IDs lado a lado
  -- apenas 1 linha com os dados dos dois times
  -- o sistema escolhe dois paises aleatoriamente
  -- mas vc pode escolher dois fixos
    -- 1 -- Brazil, rank #5, 1804 pts
    cast(max(id) * random() as int)
    as t1,
    -- 3 -- Argentina, rank #2, 1970 pts
    -- 17 -- Japan, rank #17, 1673 pts
    -- 19 -- Norway, rank #19, 1651 pts 
    -- 206 -- Bahamas, rank #206, 786 pts
    cast(max(id) * random() as int)
    as t2
    from sp.pais limit 1
), times as (
  -- pegar a forca dos times: pontos no ranking atual da Fifa
  -- rankings antigos podem ser usados! Como seria o Brasil'94 versus a Franca'98?
  -- mas cuidado com mudanças de metodologia: a Fifa mudou o cálculo em 2006 e em 2018
  select
  p1.nome as nome1, p1.sigla as sigla1, p1.pontos_atuais as pts1,
  p2.nome as nome2, p2.sigla as sigla2, p2.pontos_atuais as pts2
  from ids_times
  inner join sp.pais p1 on t1 = p1.id
  inner join sp.pais p2 on t2 = p2.id
), calculos as (
  -- o calculo é: 
  -- Fc = (forca1^2 - forca^2) / (forca1^2 + forca^2)
    -- Fc é a "força combinada" envolvida no jogo
    -- se a diferença de força entre os times for grande, esperam-se mais gols
    -- se os dois times forem muito próximos, goleadas serão mais difíceis
  -- ge1 = forca1^2 / Fc * 2.6
  -- ge2 = forca2^2 / Fc * 2.6
    -- gols esperados, normalizados entre 0 e 1
    -- se ambos forem próximos, ficará ~50% para cada um
    -- se a diferença for grande, o menor ficará com pouco
    -- os gols de cada time serão variaveis ~Normais
    -- (o ideal é usar Poisson para simulações mais robustas,
    -- mas a Normal é mais fácil de calcular e suficiente no começo)
  select
  nome1, sigla1, pts1, pts1*pts1 as quad_f1,
  nome2, sigla2, pts2, pts2*pts2 as quad_f2,
  quad_f1 + quad_f2 as soma_quads,
  case when forca1 > forca2 then forca1 else forca2 end as maior,
  case when forca1 > forca2 then forca2 else forca1 end as menor,
  (maior / menor -1) * 3 + 2.6 as Ge, --expectativa de gols no jogo (NÃO é o xG deles!!)
  round(sq_forca1 / soma_quads * Ge, 6) as ge1, -- estes dois somam 1 * Ge
  round(sq_forca2 / soma_quads * Ge, 6) as ge2, -- estes dois somam 1 * Ge
  from times
)
select
-- temos 1 linha com os dados dos dois times e seus GEs
  t1, nome1, sigla1, forca1, ge1, 
  t2, nome2, sigla2, forca2, ge2
from calculos
;
-- from sp.versus;

create or replace table sp.jogos as
with jogos0 as (
-- simulacao dos jogos: duas variaveis ~Normais para os gols
-- a função random() retorna um número ~Uniforme entre 0 e 1
-- usando método Box-Muller e depois escalando para média e desvio-padrão
-- aqui um time com ge=1.4 terá gols ~Normal(1.4 , 1.4)
-- o ideal seria uma Poisson mas a forma de cálculo é mais complexa
  select sigla1, ge1, 
  sqrt(-2 * ln(random())) * cos(2 * pi() * random()) * ge1 + ge1 as g1,
  sigla2, ge2,
  sqrt(-2 * ln(random())) * cos(2 * pi() * random()) * ge2 + ge2 as g2
  from sp.versus
  inner join generate_series(1, 100) on 1=1
)
select
sigla1, 
cast(case when g1 < 0 then 0 else g1 end as integer) as gols1, 
'X' as x,
cast(case when g2 < 0 then 0 else g2 end as integer) as gols2, 
sigla2,
case 
when gols1 > gols2 then sigla1
when gols2 > gols1 then sigla2
else 'emp' end as resultado,
sigla1 || ' ' || gols1 || ' x ' || gols2 || ' ' || sigla2 as placar -- ex: 'BRA 1 x 0 JAP'
from jogos0
;
from sp.jogos limit 10;

create or replace table sp.resumos as
-- quantidade de joos por placar e por vencedor
-- esse é o verdadeiro "placar" da simulação!
-- "Brasil ganhou 60% dos jogos, empatou 30% e perdeu 10%"
  select 
    resultado, 
    placar,
    count(*) as qtd_jogos
  from sp.jogos
  group by grouping sets((placar), (resultado), ())
  order by 1, 2 desc;

-- soltar o resumo em arquivo
COPY sp.resumos TO 'resumos.csv' (DELIMITER ';');

create or replace table sp.resumo_gols as
-- distribuição dos jogos por Qtd gols
with base as (
  select gols1, gols2, count() as qtd
  from sp.jogos
  group by all
)
pivot base
on gols2
using sum(qtd)
;

-- soltar o resumo em arquivo
COPY sp.resumo_gols TO 'resumo_gols.csv' (DELIMITER ';');
