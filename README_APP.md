# Essencia Company Mobile - POS Application

## Descrição da Aplicação

Esta é uma aplicação móvel de **Ponto de Venda (POS)** desenvolvida em Flutter para a Essencia Company. A aplicação permite realizar vendas de produtos/extras de forma eficiente através de dispositivos móveis, com suporte a múltiplos métodos de pagamento e impressão de recibos.

## Principais Funcionalidades

### 🛒 **Sistema de Vendas**
- **Seleção de Produtos/Extras**: Interface intuitiva para navegar e selecionar produtos organizados por categorias
- **Carrinho de Compras**: Sistema de carrinho com controle de quantidades (botões "+" e "-")
- **Cálculo Automático**: Cálculo em tempo real do total da venda com precisão de 2 casas decimais
- **Gestão de Eventos**: Possibilidade de associar vendas a eventos específicos

### 💳 **Métodos de Pagamento**
- **Pagamento por Cartão**: Integração com terminal **MyPOS** para pagamentos com cartão
- **Pagamento QR Code**: Sistema de pagamento através de QR code da carteira digital
- **Processamento Seguro**: Telas de processamento durante o pagamento para melhor UX

### 🧾 **Sistema de Recibos**
- **Recibo MyPOS**: Impressão automática do recibo do terminal MyPOS
- **Recibos Personalizados**: Opção de imprimir 1, 2 ou nenhum recibo personalizado adicional
- **Dados Completos**: Recibos incluem dados do POS, cliente, produtos, total e informações de faturação

### 👤 **Gestão de Clientes**
- **Dados do Cliente**: Recolha de nome, email, telefone e número de contribuinte
- **Faturação**: Opções para envio de fatura por email ou SMS
- **Integração QR**: Preenchimento automático dos dados do cliente via QR code

### 🔄 **Funcionalidades de Gestão**
- **Refresh/Atualização**: Botão de refresh para limpar carrinho e recarregar produtos
- **Navegação Fluida**: Fluxo otimizado entre páginas com limpeza automática do carrinho
- **Validação**: Validações de campos obrigatórios e estados de pagamento

## Arquitetura Técnica

### **Frontend (Flutter)**
- **Linguagem**: Dart
- **Framework**: Flutter
- **Estrutura**: Arquitetura limpa com separação por camadas:
  - `lib/presentation/`: Interfaces de usuário (views, componentes, diálogos)
  - `lib/domain/`: Lógica de negócio e requisições API
  - `lib/core/`: Serviços centrais (CartService)
  - `lib/services/`: Serviços específicos (PrinterService)

### **Integrações**
- **MyPOS SDK**: Para processamento de pagamentos com cartão
- **QR Scanner**: Para leitura de códigos QR
- **Impressão**: Sistema de impressão de recibos personalizados
- **API Backend**: Comunicação com servidor para gestão de produtos, eventos e pedidos

### **Gestão de Estado**
- **CartService**: Singleton para gestão global do carrinho de compras
- **SharedPreferences**: Armazenamento local de configurações e dados do usuário
- **StatefulWidget**: Para componentes com estado reativo

## Fluxo de Vendas

1. **Seleção de Evento**: Escolha do evento ativo
2. **Navegação por Categorias**: Filtro de produtos por categoria
3. **Seleção de Produtos**: Adição de produtos ao carrinho com quantidades
4. **Finalizar Venda**: Inserção de dados do cliente e escolha do método de pagamento
5. **Processamento**: Processamento do pagamento (cartão ou QR)
6. **Impressão**: Opções de impressão de recibos (0, 1 ou 2 recibos personalizados)
7. **Conclusão**: Retorno ao POS com carrinho limpo para nova venda

## Configurações e Personalização

- **Métodos de Pagamento**: Configuráveis por utilizador via API
- **Dados do POS**: Nome e configurações específicas do ponto de venda
- **Eventos**: Gestão dinâmica de eventos e produtos associados
- **Categorias**: Filtragem automática de categorias com produtos disponíveis

## Segurança e Confiabilidade

- **Autenticação**: Sistema de login com tokens de sessão
- **Validações**: Validação rigorosa de dados antes do processamento
- **Estados de Erro**: Tratamento adequado de erros com feedback ao utilizador
- **Backup de Dados**: Sincronização com servidor para backup automático

## Plataformas Suportadas

- **Android**: Compilação APK para dispositivos Android
- **Integração Hardware**: Compatível com terminais MyPOS
- **Impressoras**: Suporte a impressoras térmicas para recibos

---

**Desenvolvido para**: Essencia Company  
**Tecnologia**: Flutter (Dart)  
**Finalidade**: Sistema POS móvel para vendas de eventos e produtos  
**Última Atualização**: Julho 2025
