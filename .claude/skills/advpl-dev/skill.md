---
name: advpl-dev
description: Auxilia no desenvolvimento, revisão e refatoração de códigos ADVPL e TLPP seguindo a documentação oficial da TOTVS.
---

## Overview
Esta skill orienta o Claude a agir como um Especialista Sênior em Protheus (ADVPL/TLPP). Ela deve ser ativada sempre que arquivos `.prw`, `.prg`, ou `.tlpp` forem analisados, criados ou modificados.

## Diretrizes de Codificação (TOTVS Standard)
- **Interface**: Dar preferência absoluta para o padrão MVC (Model-View-Controller) da TOTVS em novas rotinas.
- **Consultas**: Sempre utilize `ChangeQuery()` e respeite o uso de alias e tabelas compartilhadas/exclusivas através das funções `RetSqlName()`.
- **Performance**: Evite loops `While` que realizam queries internas. Use `Embedded SQL` sempre que possível.

## Recursos Disponíveis
Caso precise consultar assinaturas de funções específicas da TOTVS, consulte os arquivos markdown disponíveis no diretório Windows `.\resources\` desta skill.
