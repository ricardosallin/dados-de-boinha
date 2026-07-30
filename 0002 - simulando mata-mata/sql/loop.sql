insert into mm.jogos 
with d0_ids as (
  select *
  from mm.fase_atual
), d1_times as (
  -- pegar a forca dos times
  select jogo, multiverso, fase, 
    time1, p1.nome as nome1, p1.sigla as sigla1, cast(p1.pontos_atuais_fifa as integer) as forca1,
    time2, p2.nome as nome2, p2.sigla as sigla2, cast(p2.pontos_atuais_fifa as integer) as forca2
  from d0_ids
  inner join mm.pais p1 on p1.id = time1
  inner join mm.pais p2 on p2.id = time2
), d2_calculos as (
  select jogo, multiverso, fase, 
  time1, nome1, sigla1, forca1, forca1^2 as sq_forca1,
  time2, nome2, sigla2, forca2, forca2^2 as sq_forca2,
  sq_forca1 + sq_forca2 as soma_quads,
  case when forca1 > forca2 then forca1 else forca2 end as maior,
  case when forca1 > forca2 then forca2 else forca1 end as menor,
  (maior / menor -1) * 3 + 2.6 as Ge, --expectativa de gols no jogo (NÃO é o xG deles!!)
  round(sq_forca1 / soma_quads * Ge, 6) as ge1, -- estes dois somam 1 * Ge
  round(sq_forca2 / soma_quads * Ge, 6) as ge2, -- estes dois somam 1 * Ge
  round(((forca1 - 700) / (2000 - 700)) * (0.8 - 0.3) + 0.3, 2) as pen1, -- probabilidade de marcar no penalti
  round(((forca2 - 700) / (2000 - 700)) * (0.8 - 0.3) + 0.3, 2) as pen2  -- probabilidade de marcar no penalti
  from d1_times
)
select jogo, multiverso, 
  time1, nome1, sigla1, forca1, ge1, pen1, 
  time2, nome2, sigla2, forca2, ge2, pen2,
  fase, 
  '' as placar,    -- vazio antes do jogo
  null as vencedor -- null antes do jogo 
from d2_calculos
order by 1, 2
;

drop table mm.fase_atual;

select 'foram marcados ' || count() || ' jogos para a fase ' || max(fase) || '!' as resumo
from mm.jogos
where vencedor is null
union all
select ifnull(sleep_ms((select pausa_ms from memory.params)), '')
;

/*
select *,
case when forca1 > forca2 then forca1 else forca2 end as maior,
case when forca1 > forca2 then forca2 else forca1 end as menor,
maior - menor as  dif_maior_menor,
round(( maior / menor -1) * 100, 2) as dif_maior_menor_pct
from mm.jogos order by 6;
*/

create or replace table mm.resultados_90min as
with base as (
  select jogo, multiverso,
  time1, sigla1, forca1, 
  (sqrt(-2 * ln(random())) * cos(2 * pi() * random())) * ge1 + ge1 as g1,
  time2, sigla2, forca2, 
  (sqrt(-2 * ln(random())) * cos(2 * pi() * random())) * ge2 + ge2 as g2,
  from mm.jogos
  where vencedor is null -- so jogos que ainda nao aconteceram
)
select jogo, multiverso, time1, sigla1, time2, sigla2, 
cast(case when g1 < 0 then 0 else g1 end as integer) as gols1, 
cast(case when g2 < 0 then 0 else g2 end as integer) as gols2, 
sigla1 || ' ' || gols1 || ' x ' || gols2 || ' ' || sigla2 as placar,
case
  when gols1 > gols2 then time1
  when gols2 > gols1 then time2
  else null end as vencedor_90min
from base
order by 1, 2
;

create or replace table mm.resultados_120min as
with base as (
  select j.jogo, j.multiverso, 
  j.time1, j.sigla1, j.forca1, 
  ((sqrt(-2 * ln(random())) * cos(2 * pi() * random())) * ge1 / 3) + (ge1 / 3) as g1, -- media e DP /3 porque é só 30 min!
  j.time2, j.sigla2, j.forca2, 
  ((sqrt(-2 * ln(random())) * cos(2 * pi() * random())) * ge2 / 3) + (ge1 / 3) as g2,
  from mm.jogos j
  inner join mm.resultados_90min r90 on j.jogo = r90.jogo and j.multiverso = r90.multiverso
  where vencedor_90min is null -- só jogos empatados nos 90 min
)
select jogo, multiverso, 
cast(case when g1 < 0 then 0 else g1 end as integer) as gols1, 
cast(case when g2 < 0 then 0 else g2 end as integer) as gols2, 
sigla1 || ' ' || gols1 || ' x ' || gols2 || ' ' || sigla2 as placar,
case
  when gols1 > gols2 then time1
  when gols2 > gols1 then time2
  else null end as vencedor_120min
from base
;

create or replace table mm.resultados_penaltis as
with base as (
  select j.jogo, j.multiverso, penal, 
  j.time1, j.sigla1, j.forca1, 
  cast(random() < pen1 as integer) as p1, 
  j.time2, j.sigla2, j.forca2, 
  cast(random() < pen2 as integer) as p2
  from mm.jogos j
  inner join generate_series(1, 5) as s(penal) on 1=1
  inner join mm.resultados_120min r120 on j.jogo = r120.jogo and j.multiverso = r120.multiverso
  where vencedor_120min is null -- só jogos empatados nos 120 min
  order by 1, 2, 3
)
select jogo, multiverso,
time1, sigla1, sum(p1) as penaltis1,
time2, sigla2, sum(p2) as penaltis2,
case
  when penaltis1 > penaltis2 then time1
  when penaltis2 > penaltis1 then time2
  else null end as vencedor_penaltis,
-- se empatar nos penaltis então vai no cara ou coroa
-- senão o SQL ficaria maior ainda
case
  when vencedor_penaltis is null then
  case when random() < .5 then time1 else time2 end
end as vencedor_cara_coroa
from base
group by 1, 2, 3, 4, 6, 7
order by 1, 2
;

with resultados as (
  select reg.jogo, reg.multiverso, 
  reg.sigla1 ||                                                             -- sigla time 1
  case when vencedor_cara_coroa = reg.time1 then '(V) ' else ' ' end ||     -- se vencedor no cara a cara (V), senao nada
  ifnull(reg.gols1, 0) + ifnull(pro.gols1, 0) ||                            -- gols no tempo regulamentar + prorrogacao (se tiver)
  case when penaltis1 then ' (' || penaltis1  || ') ' else '' end           -- (gols nos penaltis)
  || ' x ' ||                                                               -- X
  case when penaltis2 then ' (' || penaltis2  || ') ' else '' end ||        -- (gols nos penaltis)
  ifnull(reg.gols2, 0) + ifnull(pro.gols2, 0) ||                            -- gols no tempo regulamentar + prorrogacao (se tiver)
  case when vencedor_cara_coroa = reg.time2 then '(V) ' else ' ' end ||     -- se vencedor no cara a cara (V), senao nada
  reg.sigla2                                                                -- sigla time 2
  as placar, 
  coalesce(vencedor_90min, vencedor_120min, vencedor_penaltis, vencedor_cara_coroa) as vencedor_final
  from            mm.resultados_90min    as reg
  left outer join mm.resultados_120min   as pro on reg.jogo = pro.jogo and reg.multiverso = pro.multiverso
  left outer join mm.resultados_penaltis as pen on reg.jogo = pen.jogo and reg.multiverso = pen.multiverso
  order by 1, 2
)
update mm.jogos
set
  placar   = r.placar,
  vencedor = r.vencedor_final
from resultados r
where mm.jogos.jogo = r.jogo and mm.jogos.multiverso = r.multiverso
;

select count() || ' jogos terminaram no tempo regulamentar,' as resumo from mm.resultados_90min where vencedor_90min is not null
union all
select count() || ' foram até a prorrogação,' from mm.resultados_120min where vencedor_120min is not null
union all
select 'e ' || count() || ' foram pros penaltis!' from mm.resultados_penaltis where vencedor_penaltis is not null
union all
select 'e ' || count() || ' tiveram mais de 5 penaltis!' from mm.resultados_penaltis where vencedor_cara_coroa is not null
union all
select ifnull(sleep_ms((select pausa_ms from memory.params)), '')
;

drop table if exists mm.resultados_90min;
drop table if exists mm.resultados_120min;
drop table if exists mm.resultados_penaltis;

create or replace table mm.resumo_jogos as
-- tabela resumo de jogos jogados e a jogar, por fase
-- usada logo a seguir para ele saber automaticamente a proxima fase
with jogos_fases as (
  select f, fase, count(jogo) as qtd_jogos_a_jogar
  from mm.chaves
  group by 1, 2
), jogos_jogados as (
  select fase, count(jogo) as qtd_jogos_jogados
  from mm.jogos
  group by 1
)
select f.f, f.fase, f.qtd_jogos_a_jogar, ifnull(j.qtd_jogos_jogados, 0) as qtd_jogos_jogados
from            jogos_fases f
left outer join jogos_jogados j on f.fase = j.fase
order by 1 desc;

create or replace table mm.fase_atual as
with vencedores as (
  select jogo, multiverso, vencedor
  from mm.jogos
)
select c.fase, c.jogo, v1.multiverso, 
v1.vencedor as time1, v2.vencedor as time2
from chaves c
inner join vencedores v1 on c.jogo_origem1 = v1.jogo
inner join vencedores v2 on c.jogo_origem2 = v2.jogo and v1.multiverso = v2.multiverso
and fase = ( -- pega a proxima fase
  select fase  as proxima_fase
  from mm.resumo_jogos
  where qtd_jogos_jogados = 0
  order by f desc
  limit 1
);

/*
-- esta parte é para quando for rodar manualmente na UI do DuckDB
with qtd_check as (
  select max(fase) as fase, count(1) as qtd from mm.fase_atual
)
select case
when qtd > 0 then 'Volte para rodar a próxima fase: ' || fase
else 'Siga em frente para ver quem venceu mais multiversos!'
end as next_ 
from qtd_check
;
*/

checkpoint;