ATTACH IF NOT EXISTS './/db//fifa26mm.db' AS mm;
use mm;

-- CAMPEÕES de cada multiverso!!
COPY (
  select multiverso, placar as placar_final, 'CAMPEÃO: ' || upper(p.nome) as campeao
  from mm.jogos f 
  inner join pais p on f.vencedor = p.id
  where fase = 'FINAL'
) TO './/out//campeoes.csv' (HEADER, DELIMITER ';');


-- RANKING: maiores vencedores de multiversos!!
COPY (
  select p.nome, count(multiverso) as qtd_multiversos
  from mm.jogos f 
  inner join pais p on f.vencedor = p.id
  where fase = 'FINAL'
  group by 1
  order by 2 desc
) TO './/out//ranking.csv' (HEADER, DELIMITER ';');


-- TODAS AS CAMPANHAS do seu time favorito!!
COPY (
  with multiverso_campeao as (
    select distinct multiverso as mv
    from mm.jogos
    where fase = 'FINAL'
    -- and placar like '%ESP%'
  ), campanhas_campeas as (
    select multiverso, fase, jogo, placar
    from mm.jogos 
    where multiverso in (select mv from multiverso_campeao)
    --- and (placar like '%ESP%')
    order by multiverso, jogo
  )
  pivot campanhas_campeas
  on fase
  using max(placar)
  group by multiverso
  -- order by 3
) TO './/out//campanhas.csv' (HEADER, DELIMITER ';');


-- BACKUP de todos os jogos!!
COPY (
  select multiverso, fase, sigla1 || ' (' || forca1 || ' pts) x (' || forca2 || ' pts) ' || sigla2 as duelo, placar, 
  sigla as vencedor
  from mm.jogos j
  inner join mm.pais p on j.vencedor = p.id
) TO './/out//historico_jogos.csv' (HEADER, DELIMITER ';');


-- ANÁLISE: Argentina venceu mais multiversos do que a Espanha, porque chegou em muito mais quartas!
-- Adversários ARG eram mais fracos (CPV e AUS/EGI) do que os adversários ESP (AUT e POR/CRO)
-- Isso qualquer um já sabia, mas agora temos números!!
create or replace temp macro analise_oponentes (oponente) as table
  with pais_analise as (
    select sigla as sg, cast(pontos_atuais_fifa as integer) as f
    from pais
    where sigla = oponente
  ), jogos_analise as (
      select sg, multiverso, fase, sigla1 || ' (' || forca1 || ' pts) x (' || forca2 || ' pts) ' || sigla2 as duelo, placar, 
      sigla as vencedor,
      case when forca1 = f then forca2 else forca1 end as forca_oponente
      from mm.jogos j
      inner join mm.pais p on j.vencedor = p.id
      inner join pais_analise a on sg in (sigla1, sigla2)
  )
  select sg, fase, round(avg(forca_oponente), 1) as forca_media_oponentes, 
  sum(case when vencedor = sg then 1 else 0 end) as qtd_vitorias,
  count(1) as qtd_jogos, 
  round(qtd_vitorias * 100 / qtd_jogos, 1) as aproveitamento
  from jogos_analise
  group by 1, 2
  order by 5 desc; -- ordenação artificial das fases pela qtd jogos

COPY ( select * from analise_oponentes('ESP') ) TO './/out//analise_oponentes_esp.csv' (HEADER, DELIMITER ';');
COPY ( select * from analise_oponentes('ARG') ) TO './/out//analise_oponentes_arg.csv' (HEADER, DELIMITER ';');


select 'Total de ' || max(multiverso) || ' multiversos executados!' as resumo from mm.jogos
union all
select 'Maiores Campeões:'
;

.mode duckbox
select p.nome as País, count(multiverso) as 'Qtd Multiversos em que Foi Campeão'
from mm.jogos f 
inner join pais p on f.vencedor = p.id
where fase = 'FINAL'
group by 1
order by 2 desc
limit 5
;