import { Injectable } from '@angular/core';
import { ALIASES_COLUNA, COLUNAS_OBRIGATORIAS, LinhaImportacao, MedicaoImportacao, ValidacaoLayout } from '../models/importacao.model';

// Espelha a leitura feita em Contratos/RT69M002.prw (LerArquivo): separador ";", primeira
// linha e cabecalho, sem suporte a aspas/escaping (o CSV gerado por RT69M001 tambem nao usa
// isso -- so usa o envoltorio ="valor" para proteger codigos com zeros a esquerda no Excel).
//
// Reconhece DOIS layouts de cabecalho, nao so um: o cru de RT69M001.prw::GeraArq (nomes de
// campo -- CNE_NUMERO, CNE_ITEM, ...) e o amigavel da propria aba Exportar deste app
// (ExportarMedicaoComponent::gerarXlsx -- "Planilha", "Item", ...), para que um arquivo
// exportado por esta mesma tela possa ser reimportado sem edicao manual do cabecalho. Ver
// ALIASES_COLUNA em importacao.model.ts. Toda linha resultante (this.parse()'s retorno) fica
// indexada SEMPRE pelo nome canonico (cru) -- o resto da tela (ImportarMedicaoComponent,
// COLUNAS_GRID, etc.) nao precisa saber qual layout foi de fato importado.
//
// Numero do contrato/revisao e fornecedor/cliente NAO fazem mais parte deste parser: a tela ja
// parte do contrato posicionado no browse (ver ImportarMedicaoComponent::ngOnInit), entao o
// arquivo so precisa identificar planilha+item+produto+quantidade (TES/CC opcionais);
// descricao/UM/valor unitario/classe valor/saldo vem do cadastro da planilha via op
// "itensPlanilha", nao do arquivo.
@Injectable({ providedIn: 'root' })
export class CsvParserService {
  parse(conteudo: string): MedicaoImportacao {
    const linhasTexto = conteudo.split(/\r\n|\n|\r/).filter(linha => linha.length > 0);

    if (linhasTexto.length === 0) {
      return { colunas: [], linhas: [] };
    }

    const colunasArquivo = this.dividirLinha(linhasTexto[0]).map(valor => valor.trim());

    // Mapa coluna-do-arquivo -> nome canonico (ALIASES_COLUNA); colunas nao reconhecidas
    // mantêm o proprio nome (repassadas como vieram, ignoradas pelo restante da tela).
    const mapaCanonico = new Map<string, string>();
    for (const [canonico, aliases] of Object.entries(ALIASES_COLUNA)) {
      const encontrada = this.localizarColuna(colunasArquivo, [canonico, ...aliases]);
      if (encontrada) {
        mapaCanonico.set(encontrada, canonico);
      }
    }

    const colunas = colunasArquivo.map(coluna => mapaCanonico.get(coluna) ?? coluna);

    const linhas: LinhaImportacao[] = linhasTexto.slice(1).map(linhaTexto => {
      const valores = this.dividirLinha(linhaTexto).map(valor => this.removerEnvoltorioExcel(valor.trim()));
      const linha: LinhaImportacao = {};
      colunasArquivo.forEach((coluna, indice) => {
        const chave = mapaCanonico.get(coluna) ?? coluna;
        linha[chave] = valores[indice] ?? '';
      });
      return linha;
    });

    return { colunas, linhas };
  }

  // Confere se o cabecalho do arquivo (ja normalizado para nomes canonicos por parse() acima)
  // traz as colunas minimas para identificar o item medido -- Planilha, Item, Produto e
  // Quantidade (ver COLUNAS_OBRIGATORIAS). TES/CC ficam de fora por serem opcionais.
  validarLayout(colunas: string[]): ValidacaoLayout {
    const colunasFaltantes = COLUNAS_OBRIGATORIAS.filter(coluna => !colunas.includes(coluna));
    return { valido: colunasFaltantes.length === 0, colunasFaltantes };
  }

  // Localiza, entre as colunas do arquivo, a primeira que corresponda a algum dos aliases
  // informados (comparacao normalizada -- ver normalizar()). Devolve o nome EXATO como veio no
  // arquivo (para indexar de volta em colunasArquivo/valores), ou undefined se nenhuma bateu.
  private localizarColuna(colunasArquivo: string[], aliases: string[]): string | undefined {
    const normalizadas = colunasArquivo.map(coluna => this.normalizar(coluna));
    for (const alias of aliases) {
      const indice = normalizadas.indexOf(this.normalizar(alias));
      if (indice >= 0) {
        return colunasArquivo[indice];
      }
    }
    return undefined;
  }

  // Remove acentos, espacos nas pontas e diferencas de maiusculas/minusculas -- para que
  // "Descrição"/"descricao"/"DESCRIÇÃO" sejam todos reconhecidos como o mesmo cabecalho.
  private normalizar(texto: string): string {
    return texto
      .trim()
      .normalize('NFD')
      .replace(/[̀-ͯ]/g, '')
      .toUpperCase();
  }

  private dividirLinha(linha: string): string[] {
    return linha.split(';');
  }

  // Desfaz o envoltorio ="valor" usado pelo RT69M001 para proteger codigos com zeros a
  // esquerda de serem reinterpretados pelo Excel -- mesma logica de StripTxtExcel no ADVPL.
  private removerEnvoltorioExcel(valor: string): string {
    if (valor.length >= 3 && valor.startsWith('="') && valor.endsWith('"')) {
      return valor.substring(2, valor.length - 1);
    }
    return valor;
  }
}
