# Casa da Mãe — como publicar

Painel para registrar as contas da casa (aluguel, gás, energia, internet e outras), dividir por percentual entre Gabi, Matheus e Mãe, registrar repasses e ajudas e ver o histórico.

## 1. Supabase (banco na nuvem)

1. Entre no Supabase e abra o projeto **Mamis**.
2. Vá em **SQL Editor > New query**, cole todo o conteúdo de `supabase.sql` e clique em **Run**.
3. Vá em **Project Settings > API** e copie:
   - **Project URL**
   - **anon public key**

## 2. Configurar o painel

Abra `index.html`, procure o bloco `CONFIG` logo no início e preencha:

```js
const CONFIG = {
  SUPABASE_URL: 'https://xxxxx.supabase.co',
  SUPABASE_ANON_KEY: 'eyJ...'
};
```

Com os campos vazios, o painel abre em **modo local** (salva só no navegador, para teste).

## 3. GitHub Pages

1. Crie um repositório (ex.: `casa-da-mae`) e envie o `index.html`.
2. Em **Settings > Pages**, escolha a branch `main` e a pasta `/ (root)`.
3. Em alguns minutos o link fica disponível (`https://seu-usuario.github.io/casa-da-mae/`). Mande esse link para o Matheus e para sua mãe.

## 4. Primeiro uso

1. Clique na engrenagem e defina o percentual de cada um (precisa somar 100%).
2. Lance as contas do mês em **+ Conta**. Ao marcar "Conta já paga", informe quem pagou.
3. Quando alguém transferir a parte dele, registre em **+ Repasse** (ou use o botão **Registrar** na sugestão de acerto).
4. A ajuda extra vai em **+ Ajuda** e não entra na divisão.
5. No mês seguinte, use **Copiar as contas de [mês anterior]** e ajuste os valores de gás e energia.

## Anexos (boleto e comprovante)

- Em cada conta dá para anexar o **boleto/conta** (PDF ou foto) e, quando marcada como paga, o **comprovante de pagamento**.
- Repasses e ajudas também aceitam comprovante (PIX, transferência).
- No celular, o botão "Anexar PDF ou foto" permite tirar foto na hora. Fotos grandes são reduzidas automaticamente; limite de 10 MB por arquivo.
- Os arquivos ficam no Storage do Supabase (bucket privado `cm-arquivos`) e abrem por um link temporário.
- No modo local (sem Supabase) o limite é 2 MB, porque o arquivo fica guardado no navegador.

## Como o cálculo funciona

- **Cota** = soma de cada conta × percentual da pessoa naquela conta.
- **Já contribuiu** = contas que a pessoa pagou + repasses enviados − repasses recebidos.
- A diferença mostra quem está em dia, quem falta e quem pagou a mais. O quadro "Para equilibrar o mês" sugere os repasses.
- Cada conta guarda a própria divisão. Mudar o percentual nos ajustes afeta só as contas novas, a não ser que você marque "Aplicar a nova divisão às contas do mês".

## Segurança

O acesso está liberado para quem tiver o link do painel (a chave anon fica visível no código publicado). Para uso familiar é suficiente; se quiser restringir, dá para adicionar login por e-mail do Supabase depois.

Use **Exportar backup** de vez em quando para guardar uma cópia em JSON.
