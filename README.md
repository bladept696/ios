# Centro de Comando — iOS

App iOS (SwiftUI + WKWebView) que mostra o teu painel **exatamente igual** ao do PC.
O `app.py` continua a ser o servidor (fala com as Bitaxe/NerdQAxe, MQTT, alarmes, watchdog…);
a app iOS é o "ecrã". O `nerdqaxe-dashboard.html` já é servido pelo `app.py`, por isso
**não é preciso alterar nenhum ficheiro do painel**.

## Requisitos
- `app.py` a correr num PC/Raspberry/mini-PC na mesma rede (ou acessível por Tailscale), porta 8765.
- iPhone com iOS 15+.

## Compilar sem Mac (a partir do Windows)
1. Cria um repositório novo no GitHub (ex.: `centro-de-comando-ios`) e envia o conteúdo desta pasta
   (com `project.yml` e `.github/` na raiz do repo).
2. No GitHub: **Actions → "Build iOS" → Run workflow**. No fim, descarrega o artefacto `CentroDeComando.ipa`.
3. No Windows, instala o **Sideloadly** (ou AltStore), liga o iPhone por cabo, arrasta o `.ipa` e
   entra com o teu Apple ID. Com Apple ID gratuito a app expira ao fim de 7 dias (volta a instalar/renovar;
   o AltStore renova automaticamente). Com conta Developer (99 €/ano) dura 1 ano.
4. No iPhone: Definições → Geral → VPN e gestão de dispositivos → confiar no teu Apple ID.

## Compilar com Mac
```
brew install xcodegen
xcodegen generate
open CentroDeComando.xcodeproj
```
Em Signing & Capabilities escolhe a tua Team e corre no iPhone.

## Usar
- Na 1.ª abertura escreve o IP do servidor (ex.: `192.168.25.10`). A porta 8765 é assumida.
- Aceita o pedido de "Rede local" do iOS.
- Puxar para baixo = recarregar. Os dois botões discretos em baixo à esquerda recarregam / abrem as definições.
- Se ativaste HTTPS no painel (certificado autoassinado), escreve `https://IP:8765` — a app aceita o certificado
  apenas desse servidor.

## Limitações (do iOS)
- Quando a app está em segundo plano o iOS suspende-a: o painel deixa de atualizar e **não toca alarmes**.
  Os alarmes/watchdog do servidor continuam a correr no PC.
- Widgets do ecrã principal e notificações push exigiriam código nativo extra (WidgetKit/APNs).
