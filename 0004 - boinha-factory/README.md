# Boinha Factory V1

Gerador simples de dados sintéticos para os projetos do Dados de Boinha.

## Instalação

```bash
pip install -r requirements.txt
```

## Executando

10 Drivers por minuto:

```bash
python boinha_factory.py --config driver.json --frequency 10
```

Um Driver por segundo:

```bash
python boinha_factory.py --config driver.json --frequency 60
```

O banco SQLite `boinha.db` é criado automaticamente.

Para parar:

```text
Ctrl+C
```

## Tipos disponíveis

`uuid`, `name`, `email`, `phone_number`, `city`, `country`, `company`,
`address`, `date`, `datetime`, `integer`, `float`, `boolean`.

`integer` aceita `min` e `max`.

`float` aceita `min`, `max` e `decimals`.
