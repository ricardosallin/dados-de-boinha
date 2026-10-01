import argparse
import json
import sqlite3
import time
import uuid
from datetime import datetime

from faker import Faker


class BoinhaFactory:
    """Gera entidades sintéticas e as insere em um banco SQLite."""

    SUPPORTED_TYPES = {
        "uuid", "name", "email", "phone_number", "city", "country",
        "company", "address", "date", "datetime", "integer", "float",
        "boolean",
    }

    SQLITE_TYPES = {
        "uuid": "TEXT", "name": "TEXT", "email": "TEXT",
        "phone_number": "TEXT", "city": "TEXT", "country": "TEXT",
        "company": "TEXT", "address": "TEXT", "date": "TEXT",
        "datetime": "TEXT", "integer": "INTEGER", "float": "REAL",
        "boolean": "INTEGER",
    }

    def __init__(self, config_file, database):
        self.config = self.load_config(config_file)
        self.database = database
        self.faker = Faker("pt_BR")
        self.validate_config()
        self.create_table()

    def load_config(self, config_file):
        with open(config_file, "r", encoding="utf-8") as file:
            return json.load(file)

    def validate_config(self):
        for key in ("entity", "table", "fields"):
            if key not in self.config:
                raise ValueError(f"Configuração inválida: campo '{key}' não encontrado.")

        if not self.config["fields"]:
            raise ValueError("A entidade precisa ter pelo menos um campo.")

        for field_name, field_config in self.config["fields"].items():
            field_type = field_config.get("type")
            if field_type not in self.SUPPORTED_TYPES:
                raise ValueError(
                    f"Tipo '{field_type}' não suportado no campo '{field_name}'."
                )

    def create_table(self):
        columns = []
        for field_name, field_config in self.config["fields"].items():
            sqlite_type = self.SQLITE_TYPES[field_config["type"]]
            columns.append(f'"{field_name}" {sqlite_type}')

        sql = f'''
            CREATE TABLE IF NOT EXISTS "{self.config["table"]}" (
                {", ".join(columns)}
            )
        '''

        with sqlite3.connect(self.database) as connection:
            connection.execute(sql)
            connection.commit()

    def generate_email_from_name(self, name):
        base_email = self.faker.email()
        base_domain = base_email.split("@")[1]
        name_parts = name.lower().split()
        email = "_".join(name_parts) + f"@{base_domain}"
        return email

    def generate_value(self, field_config):
        field_type = field_config["type"]

        if field_type == "uuid":
            return str(uuid.uuid4())
        if field_type == "name":
            return self.faker.name()
        if field_type == "email":
            return self.faker.email()
        if field_type == "phone_number":
            return self.faker.phone_number()
        if field_type == "city":
            return self.faker.city()
        if field_type == "country":
            return self.faker.country()
        if field_type == "company":
            return self.faker.company()
        if field_type == "address":
            return self.faker.address().replace("\n", ", ")
        if field_type == "date":
            return self.faker.date()
        if field_type == "datetime":
            return datetime.now().isoformat(sep=" ", timespec="seconds")
        if field_type == "integer":
            return self.faker.random_int(
                min=field_config.get("min", 0),
                max=field_config.get("max", 100),
            )
        if field_type == "float":
            decimals = field_config.get("decimals", 2)
            value = self.faker.pyfloat(
                min_value=field_config.get("min", 0),
                max_value=field_config.get("max", 100),
                right_digits=decimals,
            )
            return round(value, decimals)
        if field_type == "boolean":
            return self.faker.boolean()

        raise ValueError(f"Tipo desconhecido: {field_type}")

    def generate_entity(self):
        entity = {
            field_name: self.generate_value(field_config)
            for field_name, field_config in self.config["fields"].items()
        }
        if "email" in self.config["fields"] and "name" in self.config["fields"]:
            entity["email"] = self.generate_email_from_name(entity["name"])
        return entity

    def insert_entity(self, entity):
        fields = list(entity.keys())
        columns = ", ".join(f'"{field}"' for field in fields)
        placeholders = ", ".join("?" for _ in fields)

        sql = f'''
            INSERT INTO "{self.config["table"]}" ({columns})
            VALUES ({placeholders})
        '''

        with sqlite3.connect(self.database) as connection:
            connection.execute(sql, [entity[field] for field in fields])
            connection.commit()

    def run(self, frequency):
        if frequency <= 0:
            raise ValueError("A frequência precisa ser maior que zero.")

        interval = 60 / frequency

        print("Boinha Factory iniciado.")
        print(f"Entidade: {self.config['entity']}")
        print(f"Tabela: {self.config['table']}")
        print(f"Frequência: {frequency:g} objeto(s)/minuto")
        print(f"Intervalo: {interval:.2f} segundo(s)")
        print("Pressione Ctrl+C para parar.\n")

        try:
            while True:
                entity = self.generate_entity()
                self.insert_entity(entity)
                print(
                    f"[{datetime.now():%Y-%m-%d %H:%M:%S}] "
                    f"{self.config['entity']} inserido: {entity}"
                )
                time.sleep(interval)
        except KeyboardInterrupt:
            print("\nBoinha Factory encerrado.")


def main():
    parser = argparse.ArgumentParser(
        description="Boinha Factory - gerador de dados sintéticos"
    )
    parser.add_argument(
        "--config", required=True, 
        help="Arquivo JSON da entidade."
    )
    parser.add_argument(
        "--frequency", type=float, required=True,
        help="Quantidade de objetos por minuto."
    )
    parser.add_argument(
        "--database", default="boinha.db",
        help="Arquivo SQLite. Padrão: boinha.db"
    )
    args = parser.parse_args()

    factory = BoinhaFactory(args.config, args.database)
    factory.run(args.frequency)


if __name__ == "__main__":
    main()
