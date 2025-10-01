# Sprint 03 | Cloud

## Integrantes

| Nome |  RM  |
| ---- | :--: |
| Otavio Miklos Nogueira | 554513 |
| Luciayla Yumi Kawakami | 557987 |
| João Pedro Amorim Brito | 559213 |


## Links
Youtube: 

## Descrição
A aplicação é uma API juntamente com um projeto MVC ambos desenvolvidos com o auxílio do Spring Boot, o projeto possui 3 fluxos principais, o primeiro é o de login/cadastro onde é possível entrar ou criar uma conta, garantindo assim o acesso aos demais fluxos. Outro fluxo interessante é o de criar uma nova filial, onde você insere o nome e o endereço. Com uma nova filial em mãos, você pode adicionar motos a essa filial. Garantindo assim uma organização melhor para cada filial da Mottu.

## Benefícios
Garantir a organização geral das filiais e ter um controle e uma visão clara das filiais já existentes e das motos que cada uma delas possui. A aplicação é simples, o que facilita o uso para os organizadores de pátio.


## Arquitetura 

```mermaid
flowchart TD
    User[Usuário / Navegador] -->|HTTPS Request| AppService[Azure App Service<br/>(Spring Boot MVC + API)]

    AppService -->|JDBC| Database[Azure SQL Database]

    subgraph Azure["Azure Cloud"]
        AppService
        Database
        Monitor[Azure Monitor / Application Insights]
        KeyVault[Azure Key Vault]
    end

    AppService --> Monitor
    AppService --> KeyVault

    subgraph DevOps["CI/CD Pipeline"]
        Repo[GitHub / Azure DevOps Repo]
        Pipeline[Build & Deploy Pipeline]
    end

    Repo --> Pipeline --> AppService
```