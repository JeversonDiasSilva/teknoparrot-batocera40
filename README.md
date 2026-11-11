# TeknoParrot no Batocera 40

Suporte ao **TeknoParrot** (UI Linux 2.0) no Batocera 40, com o **STAR WARS: Battle Pod** funcionando
(loader OpenParrot), controles configurados e uma tela de carregamento (splash) bonita no EmulationStation.

> O **Wine** usado é o **ge-custom que já vem no Batocera 40** (`/usr/wine/ge-custom`). Ele **não** é instalado
> por aqui — toda instalação do Batocera 40 já tem.

## Instalar

Com internet, direto no Batocera (SSH ou terminal):

```bash
curl -fsSL https://raw.githubusercontent.com/__REPO__/main/install.sh | bash
```

Só o sistema, sem o jogo:

```bash
curl -fsSL https://raw.githubusercontent.com/__REPO__/main/install.sh | bash -s -- --sem-jogo
```

A partir de pacotes já baixados (sem internet), coloque os `.squashfs` numa pasta e rode:

```bash
TP_LOCAL=/caminho/dos/pacotes bash install.sh
```

Depois, se o sistema **TeknoParrot** não aparecer, reinicie o EmulationStation (Menu > Sair > Reiniciar EmulationStation).

## O que é instalado

| Pacote | Vai para | O que é |
|---|---|---|
| `teknoparrot-app-batocera40.squashfs` | `/userdata/system/.dev/apps/teknoparrot` | O TeknoParrot UI, loaders, scripts e o splash |
| `teknoparrot-prefix-batocera40.squashfs` | `/userdata/system/.local/share/TeknoParrotUI` | Prefixo Wine já configurado (controles + registro) |
| `starwars-battlepod.squashfs` | `/userdata/roms/teknoparrot/StarWarsBattlePod` | O jogo Star Wars Battle Pod |

Também posiciona: o sistema do ES (`es_systems_teknoparrot.cfg`), as teclas de saída (`evmapy/teknoparrot.keys`),
o atalho de app (`teknoparrot.desktop`), o arquivo do jogo (`Star Wars Battle Pod.teknoparrot`) e a imagem.

O instalador **cria** `/userdata/system/.dev/apps` se não existir (`mkdir -p`), e guarda qualquer instalação anterior
em `*.antes-<data>`.

## Usar

- Abra **STAR WARS: Battle Pod** no sistema TeknoParrot. A 1ª vez pode levar ~40s (tela **CARREGANDO...**).
- **Sair do jogo:** SELECT+START ou HOTKEY+START.
- **Controles:** já vêm no perfil (tiro=A, arma=B, visão=RB, Start=START, analógicos).
  Para reconfigurar: abra o TeknoParrot pelo menu de apps → **CONTROLLER SETUP**.
- **Log:** `/userdata/system/logs/teknoparrot.log`.

## Observações

- Jogos com o **loader fechado do TeknoParrot** (protegido por Themida) — ex.: Sega Racing Classic, HOTD Scarlet Dawn,
  Sonic Dash, Aliens Armageddon, Jurassic Park — **não rodam** neste PC (erro "cannot run under a Virtual Machine").
  Só rodam jogos do **OpenParrot** (aberto), como o Star Wars.
- Testado no Batocera 40, PC real (Ryzen 3 2200G). Veja `DOCUMENTACAO.md` dentro do app para os detalhes técnicos.

## Aviso

O pacote do jogo contém conteúdo comercial. Use apenas se você tiver direito a ele.
