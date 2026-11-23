# Arquitetura Medallion com Spark e dados de clientes da Olist

Este projeto demonstra um pipeline de dados em arquitetura Medallion usando Apache Spark e PySpark. O notebook realiza a leitura do conjunto de clientes da Olist, identifica registros associados a clientes repetidos e gera uma agregação por estado na camada Gold.

## Base de dados

Os dados utilizados são o arquivo `olist_customers_dataset.csv`, disponível no dataset **Brazilian E-Commerce Public Dataset by Olist**, hospedado no Kaggle:

- [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
- Arquivo selecionado: [`olist_customers_dataset.csv`](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce?select=olist_customers_dataset.csv)

Cada linha representa um registro de cliente relacionado a um pedido. O conjunto contém os campos:

| Coluna | Tipo inferido | Descrição |
|---|---|---|
| `customer_id` | string | Identificador do cliente em um pedido |
| `customer_unique_id` | string | Identificador único do cliente |
| `customer_zip_code_prefix` | integer | Prefixo do CEP |
| `customer_city` | string | Cidade do cliente |
| `customer_state` | string | Unidade federativa do cliente |

## Notebook

O processo está implementado em:

- [`notebook_customer_medallion_architecture.ipynb`](./notebook_customer_medallion_architecture.ipynb)

## Arquitetura do processo

```text
CSV da Olist
     |
     v
Bronze: clientes_base/bronze
     |
     v
Silver:
  - count_unique_id
  - count_unique_id_duplicated
  - count_unique_id_nduplicated
     |
     v
Gold: clientes_base/gold/custumer_state_count
```

### Bronze

O arquivo CSV é lido como um Spark DataFrame. Em seguida, os dados são persistidos no formato Parquet, preservando a estrutura original da base:

```text
clientes_base/bronze
```

Essa camada funciona como a representação mais próxima dos dados recebidos.

### Silver

Na camada Silver, uma janela do Spark particiona os dados por `customer_unique_id` e calcula quantas vezes cada identificador único aparece:

```python
janela = Window.partitionBy("customer_unique_id")
df_filtered = df_bronze.withColumn(
    "count_unique_id",
    F.count("customer_unique_id").over(janela)
)
```

A partir desse cálculo, o processo separa os dados em:

| Caminho | Conteúdo |
|---|---|
| `clientes_base/silver/count_unique_id` | Todos os registros com a contagem por cliente |
| `clientes_base/silver/count_unique_id_duplicated` | Registros cujo identificador único aparece mais de uma vez |
| `clientes_base/silver/count_unique_id_nduplicated` | Registros cujo identificador único aparece uma única vez |

A separação permite isolar registros duplicados para análise ou quarentena e manter uma base limpa para as agregações finais.

### Gold

A partir dos registros sem duplicidade, o notebook agrupa os clientes por estado e conta o número de registros de cada UF:

```python
df_gold_state = (
    df_silver_clean
    .groupby("customer_state")
    .agg(F.count("customer_state").alias("customer_state_count"))
)
```

O resultado é armazenado em:

```text
clientes_base/gold/custumer_state_count
```

As três camadas são persistidas no formato Parquet para possibilitar leitura posterior sem repetir todo o processamento.

## Resultados observados

Na execução registrada no notebook:

- Total de registros na base: **99.441**
- Registros duplicados por `customer_unique_id`: **6.342**
- Registros únicos/limpos: **93.099**
- A unidade federativa com maior quantidade na base limpa foi **SP**, com **38.989** registros

Os diretórios Parquet são sobrescritos em cada execução graças ao modo `overwrite`.

## Pré-requisitos

- Python 3
- Apache Spark
- PySpark
- Jupyter Notebook ou JupyterLab
- Arquivo `csv/olist_customers_dataset.csv`

Exemplo de dependência Python:

```bash
pip install pyspark jupyter
```

## Como executar

1. Baixe o arquivo `olist_customers_dataset.csv` do Kaggle.
2. Coloque-o em `csv/olist_customers_dataset.csv`, relativo ao diretório do notebook.
3. Abra o notebook em Jupyter ou JupyterLab.
4. Execute as células em ordem.

```bash
jupyter notebook notebook_customer_medallion_architecture.ipynb
```

## Estrutura esperada

```text
mba_spark/
├── README.md
├── notebook_customer_medallion_architecture.ipynb
├── csv/
│   └── olist_customers_dataset.csv
└── clientes_base/
    ├── bronze/
    ├── silver/
    │   ├── count_unique_id/
    │   ├── count_unique_id_duplicated/
    │   └── count_unique_id_nduplicated/
    └── gold/
        └── custumer_state_count/
```
