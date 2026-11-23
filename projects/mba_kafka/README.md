# ShopVibe: Prática de Trabalho

Este repositório contém a arquitetura de dados em tempo real da **ShopVibe**, um e-commerce fictício de moda e acessórios. O objetivo deste projeto é resolver problemas de latência na tomada de decisão (como vendas sem estoque e detecção tardia de fraudes) substituindo a extração em batch por um pipeline de streaming contínuo.

## Objetivos do Projeto
Atender aos requisitos de negócio estabelecidos:
- **RF01:** Capturar cada novo pedido e disponibilizá-lo em um tópico do Kafka em poucos segundos.
- **RF02:** Armazenar os eventos brutos para reprocessamento (camada raw / bronze).
- **RNF01:** Latência: O evento vai da origem ao destino em poucos segundos. 
- **RNF02:** Durabilidade: Nenhum pedido se perde se um componente cair.
- **RNF03:** Escalabilidade: Suportar 20 vezes o volume normal (cerca de 300 mil pedidos/dia).
- **RNF04:** Reprodutibilidade: Outra pessoa consegue repetir o que o grupo fez.
- **RNF05:** Custo: Usar apenas ferramentas open source.


## Avaliação
Atender aos entregáveis estabelecidos:
- **ADRs:** Contexto ligado ao problema da ShopVibe; alternativas reais; consequências negativas declaradas; clareza. - Localizado na pasta "requisitos_tecnicos"
- **Desenho da solução:** Todas as camadas; coerência com os ADRs; distinção entre implementado e evolução; legibilidade. - Localizado na pasta ""
- **Demonstração prática:** Os quatro itens da Seção 3 aparecem no vídeo; o grupo explica o que acontece em cada passo. - Localizado em 
    - O ambiente em execução (os contêineres ligados).
    - Um pedido novo sendo criado na origem.
    - O evento desse pedido aparecendo no tópico do Kafka, em poucos segundos.
    - Os eventos gravados na camada bruta (bronze).


## Arquitetura e Tecnologias
O pipeline foi desenhado para capturar as mudanças diretamente no banco de dados sem sobrecarregar a aplicação principal:
* **Origem:** PostgreSQL (Tabelas `estoque`, `orders`, `itens_pedido`, `carrinho`).
* **Streaming:** Apache Kafka & Kafka Connect (MinIO e Debezium).
* **Armazenamento (Bronze):** MinIO.
* **Possivel Processamento:** Python (Jupyter, MinIO).

---

## Como executar o projeto (Reprodutibilidade)

### Pré-requisitos
* Windows (Não testamos em outros sistemas)
* Docker Desktop.
* Git.

### Passo 1: Construir as imagens customizadas
Antes de subir a infraestrutura, é necessário compilar as imagens customizadas do cliente MinIO (MC) e utilizar da imagem do professor do MinIO, que preparam nosso datalake e preparam os buckets (arquitetura medalhão) automaticamente.

Fizemos uma delas devido a um problema em imagens do laboratório. O repositório do quak / docker teve suas imagens retiradas. Em virtude disso, utilizamos do repositório do Git para buildarmos nossas imagens.


```bash
# Constrói a imagem do MinIO customizado -- Deprecada
# docker image build -t minio-customizado:latest ./minio_customizado/ 

# Constrói a imagem do cliente MC (MinIO Client)
docker image build -t mc-customizado:latest ./minio_mc/
```

### Passo 2: Subir a infraestrutura
Inicie todos os serviços - presente do Docker Compose - em background.

```bash
docker compose up -d
```

### Passo 3: Configurar Credenciais do Data Lake (MinIO)
Gere a chave de acesso (Access Key) no Minio para que o Kafka Sync faça a gravação dos arquivos JSON no bucket `bronze`.

URL: http://localhost:9001/
User: MINIO_ROOT_USER
Pass: MINIO_ROOT_PASSWORD

Agora podemos utilizar da Interface do MinIO para conseguirmos adicionar o acess key:

Access Key: shopvibe
Secret Key: labdata123

Contudo, também há a possibilidade de usar o terminal.

```bash
docker exec -it mc /bin/sh -c "/usr/bin/mc admin user svcacct add myminio admin --access-key 'shopvibe' --secret-key 'labdata123'"
```

### Passo 4: Registrar os Conectores (Debezium e S3 Sink)
Os conectores são ativados com a chamada API abaixo passando o parametro "Accept: application/json":

- Entre no container

```bash

docker exec -it kafkaConect bash

```
- Fazer a chamada .json abaixo no container do KafkaConect para possibilitar o Kafka Broker entenda as informações de transações do Debezium como Source.

```bash

# Curl para envio do json
curl -X PUT -d @/conectores/conector-postgres.json http://localhost:8083/connectors/connector-postgres/config -H 'Content-Type: application/json' -H 'Accept: application/json'

# Teste para aparecer o "Running"
curl http://localhost:8083/connectors/connector-postgres/status

```

- Fazer a chamada .json abaixo no container do KafkaConect para possibilitar que o kafkaConect Sync transfira as mensagens dos tópicos em JSON usando o plugin S3 Sink.

```bash

# Curl para envio do json
curl -X PUT -d @/conectores/conector-minio.json http://localhost:8083/connectors/connector-minio/config -H 'Content-Type: application/json' -H 'Accept: application/json'

# Teste para aparecer o "Running"
curl http://localhost:8083/connectors/connector-minio/status

```

## Consumo de Dados 
Com os conectores em estado RUNNING, qualquer nova inserção ou atualização no PostgreSQL gerará uma mensagem no Kafka, que ira mandar um arquivos JSON no bucket bronze do MinIO.

## Documentação (ADRs)
As decisões arquiteturais estão documentadas na pasta ./requisitos_tecnicos


# Antigo
```bash

docker exec -it mc /bin/sh -c "/usr/bin/mc admin user svcacct add myminio admin --access-key 'shopvibe' --secret-key 'labdata123'"

docker image build -t minio-customizado:latest ./minio_customizado/

docker image build -t mc-customizado:latest ./minio_mc/

docker exec -it kafkaConect bash

curl -X PUT -d @/conectores/conector-postgres.json http://localhost:8083/connectors/connector-postgres/config -H 'Content-Type: application/json' -H 'Accept: application/json'

curl http://localhost:8083/connectors/connector-postgres/status

curl -X PUT -d @/conectores/conector-minio.json http://localhost:8083/connectors/connector-minio/config -H 'Content-Type: application/json' -H 'Accept: application/json'

curl http://localhost:8083/connectors/connector-minio/status

docker exec -it mc /bin/sh -c "/usr/bin/mc admin user svcacct add myminio admin --access-key 'shopvibe' --secret-key 'labdata123'"

```
