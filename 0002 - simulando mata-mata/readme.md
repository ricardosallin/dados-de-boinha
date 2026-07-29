# Simulando Mata-Matas inteiros com SQL

> Simulação de um campeonato de futebol utilizando apenas SQL e DuckDB.

---

# 🎯 Objetivo

Como simular milhares de campeonatos? Vamos transformar a força de cada time em probabilidades de vitória, e partir das chaves de mata-mata da Copa 2026 (Espanha X Austria, Argentina X Cabo Verde etc) para ver as possíveis mudanças de chaves e outros eventuais campeões.

No final, a disputa será: quem venceu mais Multiversos?

---

# 💡 Motivação

Este experimento foi criado para mostrar que SQL pode ser utilizado para muito mais do que consultas em bancos de dados, permitindo construir simulações relativamente complexas utilizando apenas tabelas e queries.

---

# 📚 Conceitos utilizados

- SQL: DuckDB
- Estatística: Distribuição Normal, Probabilidade Acumulada (CDF), Monte Carlo
- Random Number Generation

---

# 🎓 O que este projeto ensina

Após estudar este experimento você terá contato com:

- Criação de tabelas
- INSERT
- UPDATE
- CTEs
- JOINs
- Window Functions
- Geração de números aleatórios
- Distribuições estatísticas
- Simulações de Monte Carlo
- Otimização de consultas

---

# 📂 Estrutura

```
.
├── sql/          - onde estão os scripts
├── db/           - onde fica o arquivo .db com o banco DuckDB
├── in/           - bases prontas: Ranking Fifa e chaves do mata-mata
├── out/          - analises geradas após rodar os multiversos
└── README.md     - este texto
```

---

# ▶️ Como executar

0. Clone este repositório numa pasta local no seu computador
1. Copie o executável do DuckDB para a sua pasta local
2. Abra um terminal apontando para a sua pasta local
3. Execute `duckdb -f sql/run.sql`
4. Serão gerados arquivos na pasta out/ e o banco em db/
5. (opcional) Altere os parâmetros no run.sql (linhas 7-8) volte ao passo 3

---

# 🔬 Modelo utilizado

1. Cada país possui um índice de Força. Aqui estamos usando os pontos no Ranking da Fifa.
2. A cada jogo, os índices dos dois países são convertidos em expectativa de gols.
3. Uma distribuição estatística gera o número de gols de cada jogo.
4. O resultado alimenta a tabela do campeonato.
5. O processo é repetido milhares de vezes.

---

# 📊 Tabelas

| Tabela | Descrição |
|---------|-----------|
| pais | Cadastro dos times |
| chave | "Molde" para montar a chave em cada multiverso |
| fase_atual | Tabela temporária com a parcela da chave correspondente à fase atual (oitavas, quartas etc) |
| jogos | Jogos do campeonato, com infos dos dois países e (depois do jogo) o placar |
| resultados_90min, _120min, _penaltis | Tabelas temporárias com os gols em cada etapa de cada jogo |
| resumo_jogos | Tabela temporária para indicar ao DuckDB qual a próxima fase |

---

# 📈 Resultados

O que o projeto produz?

Exemplo:

- Classificação final dos países por quantidade de multiversos em que foi campeão
- Histórico completo de todos os jogos em todos os multiversos
- Análise de força dos oponentes

---

# 🧪 O que o modelo NÃO capta

- Qualidade individual de jogadores
- Fator casa
- Efeitos psicológicos (euforia, apatia) durante o jogo>
	- Cartões
	- Lesões
- Clima

---

# 🎥 Vídeo relacionado

https://youtu.be/lHXgLJxemiQ

---

# 📜 Licença

MIT