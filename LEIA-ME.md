# Casa da Mãe — como publicar

Painel para registrar as contas da casa (aluguel, gás, energia, internet e outras), dividir por percentual entre Gabi, Matheus e Mãe, registrar repasses e o Extra do Mês e ver o histórico.

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
4. Valores a mais vão em **+ Extra do Mês** e não entram na divisão.
5. Para ser lembrado do aluguel: engrenagem → **Lembrete do aluguel** → Adicionar ao Google Agenda (todo dia 9, véspera do vencimento).
6. No mês seguinte, use **Copiar as contas de [mês anterior]** e ajuste os valores de gás e energia.

## Anexos (boleto e comprovante)

- Em cada conta dá para anexar o **boleto/conta** (PDF ou foto) e, quando marcada como paga, o **comprovante de pagamento**.
- Repasses e Extra do Mês também aceitam comprovante (PIX, transferência).
- No celular, o botão "Anexar PDF ou foto" permite tirar foto na hora. Fotos grandes são reduzidas automaticamente; limite de 10 MB por arquivo.
- Os arquivos ficam no Storage do Supabase (bucket privado `cm-arquivos`) e abrem por um link temporário.
- No modo local (sem Supabase) o limite é 2 MB, porque o arquivo fica guardado no navegador.

## Como o cálculo funciona

- **Cota** = soma de cada conta × percentual da pessoa naquela conta.
- **Já contribuiu** = contas que a pessoa pagou + repasses enviados − repasses recebidos.
- A diferença mostra quem está em dia, quem falta e quem pagou a mais. O quadro "Para equilibrar o mês" sugere os repasses.
- Cada conta guarda a própria divisão. Mudar o percentual nos ajustes afeta só as contas novas, a não ser que você marque "Aplicar a nova divisão às contas do mês".

## Segurança e acesso

O painel é fechado: só entra quem fizer login com **celular + senha**, e só os números cadastrados na tabela `cm_membros` (Gabi, Matheus e Mãe). Quem tiver só o link, ou a chave pública que aparece no código, não vê nem altera nada, nem as contas nem os arquivos. O bloqueio é feito no próprio Supabase (RLS).

- O login fica salvo no aparelho. Para sair ou trocar a senha: engrenagem → **Sua conta**.
- **Esqueceu a senha?** Não há recuperação por SMS. É preciso gerar uma nova senha pelo Supabase (peça ao Claude).
- **Incluir alguém novo:** criar o usuário no Supabase (login interno `55DDDNUMERO@mamis.app`) e adicionar o número em `cm_membros`.

Use **Exportar backup** de vez em quando para guardar uma cópia em JSON.
