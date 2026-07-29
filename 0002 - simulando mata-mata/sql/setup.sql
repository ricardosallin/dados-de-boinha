ATTACH IF NOT EXISTS './/db//fifa26mm.db' AS mm;
use mm;

select 'Executando ' || qtd_multiversos || ' multiversos!' as resumo
from memory.params
union all
select 'Cada um é uma chave completa de mata-mata,'
union all
select 'das 16 avos de final até a grande FINAL!'
union all
select ifnull(sleep_ms((select pausa_ms from memory.params)), '');

CREATE OR REPLACE TABLE pais AS
SELECT *
FROM read_csv('.//in//pais.csv',
    delim= ';',
    header = true,
    columns = {
        'id': 'int',
        'nome': 'VARCHAR',
        'sigla': 'VARCHAR',
        'rank_atual_fifa': 'int',
        'pontos_atuais_fifa': 'float'
    });

CREATE OR REPLACE TABLE mm.chaves AS
SELECT *
FROM read_csv('.//in//chaves.csv',
    delim= ';',
    header = true,
    columns = {
        'f': 'int',
        'fase': 'VARCHAR',
        'jogo': 'int',
        'jogo_origem1': 'int',
        'jogo_origem2': 'int',
        'time1': 'int',
        'time2': 'int'
    });

create or replace table mm.fase_atual as
select fase, jogo, multiverso, time1, time2
from mm.chaves
inner join generate_series(1, (select qtd_multiversos from memory.params)) as s(multiverso) on 1=1  
where f = 16
order by 1, 2, 3;


create or replace table mm.jogos(
  jogo       INTEGER, -- cada jogo se repete nos multiversos (talvez com times diferentes)
  multiverso INTEGER, -- cada jogo se repete nos multiversos (talvez com times diferentes)
  -- dados do primeiro dos dois times (sem nenhuma ordem em particular):
  time1      INTEGER, -- ID na tabela
  nome1      VARCHAR, -- nome inteiro
  sigla1     VARCHAR, -- sigla usada no placar
  forca1     INTEGER, -- pontos no ranking fifa
  ge1        DOUBLE,  -- gols esperados. resultado do cálculo abaixo
  pen1       DOUBLE,  -- penaltis esperados (caso o jogo vá pros penaltis)
  -- dados do segundo dos dois times:
  time2      INTEGER, -- ID na tabela
  nome2      VARCHAR, -- nome inteiro
  sigla2     VARCHAR, -- sigla usada no placar
  forca2     INTEGER, -- pontos no ranking fifa
  ge2        DOUBLE,  -- gols esperados. resultado do cálculo abaixo
  pen2       DOUBLE,  -- penaltis esperados (caso o jogo vá pros penaltis)
  -- resultado do jogo, considerando todas as etapas:
  -- tempo regulamentar / prorrogacao / penaltis / cara-ou-coroa
  fase       VARCHAR, -- 16 avos / oitavas / quartas / semi / FINAL
  placar     VARCHAR, -- placar em texto
  vencedor   INTEGER  -- ID do time q ganhou
);

