# ZFCert Java 抽出の検証手順

issue #28 (https://github.com/proof-ninja/rocq/issues/28) の検証手順書。
java.ml を修正するたびにこの手順を再実行し、「javac エラーゼロ + ランタイム検証
全パス」が保たれていることを確認する。

ワンコマンド版: このディレクトリの [`zfcert-check.sh`](./zfcert-check.sh) が
下記のステップ 3〜5(抽出 → javac → ランタイム検証)を自動実行する
(前提: ステップ 0〜2 が済んでいること)。

```sh
doc/java-extraction/zfcert-check.sh
```

## 前提となる配置

3 つのリポジトリを同じ親ディレクトリに並べる(sibling 配置)。

| パス | 内容 |
|------|------|
| `<親>/rocq` | この fork。`make world` でビルド済みであること |
| `<親>/stdlib` | rocq-prover/stdlib。fork の rocq でビルド済みであること |
| `<親>/zfcert` | mir-ikbch/zfcert の clone |

以下の各ステップのコマンドは **fork のルート(`<親>/rocq`)から始める**前提で
書いてあり、sibling は `../stdlib` / `../zfcert` の相対パスで参照する
(`cd ../zfcert` のように書いてあるので、3 つのどこにいても同じコマンドで移動できる)。
`zfcert-check.sh` も自身の位置から sibling を割り出す。

## 0. 初回のみ: リポジトリの取得

```sh
git clone https://github.com/proof-ninja/rocq.git -b doc/zfcert-verification   # この fork(手順書を含むブランチ)
cd rocq
git clone https://github.com/mir-ikbch/zfcert ../zfcert
git clone https://github.com/rocq-prover/stdlib ../stdlib
```

## 1. 初回のみ: Stdlib のビルド

ZFCert は Stdlib(`List` / `PeanoNat` / `String` / `Bool` / `DecimalString`)に
依存する。fork のビルドには Corelib しか入っていないため(Rocq 9 で Stdlib は
本体から分離された)、**fork の rocq で** Stdlib をビルドする必要がある。

```sh
cd ../stdlib
PATH="$(cd ../rocq && pwd)/_build/install/default/bin:$PATH" make -j"$(nproc)"
```

(`PATH` は相対パスにできないので `pwd` で絶対パスにしている。)

- 2026-08-27 時点の stdlib master は fork (9.3+alpha) でそのまま全ビルドできる。
  ビルドが通らなくなったら、fork のベース時期に近い stdlib のコミットに checkout
  し直す(バージョン不整合はデバッグ対象ではない)。
- `make install` は**使わない**。インストール先の `_build/install/default` は
  fork の `make world` で再生成されて消えるため。参照は常に
  `-Q ../stdlib/theories Stdlib` で行う。
- fork の rocq を再ビルドしても、kernel のインターフェースが変わらない限り
  stdlib の .vo はそのまま使い回せる。`Compiled library ... makes inconsistent
  assumptions` 系のエラーが出たら stdlib を `make clean && make` し直す。

## 2. ZFCert の Rocq ソースのコンパイル

java.ml の修正だけなら .vo は変わらないので再実行不要。fork の rocq を
再ビルドした直後や初回のみ:

```sh
cd ../zfcert
ROCQ=../rocq/_build/install/default/bin/rocq
for f in FOL ZFC ProofState TacticCompleteness NamedProofState NamedCommands \
         CertifiedSession GlobalEnvironment Audit; do
  $ROCQ c -q -Q ../stdlib/theories Stdlib -Q coq ZFCert coq/$f.v || break
done
```

- 全 9 ファイルが通ること。`From Coq` の deprecation 警告は無害。

## 3. Java 抽出

抽出エントリポイントは `../zfcert/ExtractJavaProofState.v`
(zfcert リポジトリ直下、untracked)。消えていた場合は本書末尾の付録から復元する。
これは `coq/ExtractProofState.v` から OCaml 専用部分(`ExtrOcaml*` の import と
`Extract Constant nat_to_decimal_string`)を除き、出力先と言語を Java に変えた
もので、**抽出対象の 50 定義のリストは同一**。

```sh
cd ../zfcert
ROCQ=../rocq/_build/install/default/bin/rocq
OUT=/tmp/zfcert-java   # 出力先は任意
mkdir -p $OUT
$ROCQ c -q -Q ../stdlib/theories Stdlib -Q coq ZFCert \
  ExtractJavaProofState.v
```

※ 出力先は `ExtractJavaProofState.v` 内の `Set Extraction Output Directory` で
指定されている。変えたい場合はそこを書き換える。

**期待**: 抽出コマンド自体はエラーなしで完走し、`zfcert.java` が生成される。
抽出段階のエラーは新規バグとして扱う。

## 4. javac によるコンパイル

```sh
cd <出力先>
javac -J-Duser.language=en -Xmaxerrs 2000 zfcert.java 2> javac_errors.txt
grep -c "error:" javac_errors.txt          # 総エラー数
grep "error:" javac_errors.txt | sed 's/zfcert.java:[0-9]*: //' | sort | uniq -c | sort -rn
```

`-J-Duser.language=en` は javac のメッセージを英語に固定するため(シェルのロケールに
よってメッセージ言語が変わり、`error:` の grep が効かなくなるのを防ぐ)。

**期待**: エラーゼロ。エラーが出たら上記の内訳で分類し、issue 化する。

### 経緯

| 時点 | 総エラー数 | 内容 |
|------|-----------|------|
| 2026-08-27, 修正前 | 921 | #31 (String シャドウイング) 401 件、#32 (Record 不整合とその波及) 520 件 |
| #31 修正後 | 520 | 残りは全て #32 系 |
| #32 修正後 | 0 | 独立したキャスト漏れは無かった |

注意: 型シノニム対応(PR #27)を含まないビルドでは構文エラーで javac が意味解析に
進まないため、件数比較は PR #27 を含むビルドで行うこと。

## 5. ランタイム検証

ドライバは同ディレクトリの [`DriverZfcert.java`](./DriverZfcert.java)。
ZFCert の `src/self_test.ml` の抽出カーネル駆動部
(`Zfcert_kernel.start_with_constants` → `rule_step` → `solved` → `finalize`)を
Java に移植したもので、named formula を直接構築して certified セッションを駆動する。

```sh
cd /tmp/zfcert-java   # 抽出出力先
cp <fork のルート>/doc/java-extraction/DriverZfcert.java .   # 出力先からは相対にできないので絶対パスで
javac zfcert.java DriverZfcert.java
java DriverZfcert
```

チェック内容(12 件):

| テスト | 内容 |
|--------|------|
| refl | `∀x, x = x` を `all_intro; equal_refl` で証明 → finalize → certificate 2 ステップ → replay 成功 |
| constants | `start_with_constants ["empty"]` で `empty = empty` を `equal_refl` → finalize(self_test.ml の移植) |
| fixed axiom | `∃e, ∀x, ¬(x ∈ e)` を `NFixedAxiomRule` で証明 → replay。**ドライバ製文字列とカーネル内部文字列が照合される唯一のテスト**(Ascii の LSB-first エンコーディングの検証を兼ねる) |
| impl/hypothesis | `(p = p → p = p)` を `impl_intro H; hypothesis H` で証明 → replay |
| bad refl | `x = y` への `equal_refl` が `NCoreError` で拒否される |
| unknown hypothesis | 未知の仮説名参照が `NHypothesisNotFound` で拒否される |

- **期待**: 「All 12 runtime checks passed.」が出ること(2026-09-01、PR #34 マージ後の
  ビルドで確認済み)。回帰基準は「javac エラーゼロ + ランタイム検証全パス」で、
  `zfcert-check.sh` が両方を検査する。
- 対象範囲: 抽出カーネル(certified セッション)のみ。`.zfp` サンプルの実行には
  OCaml 側の表層パーサ(`Proof_session` / `Parser`)が必要で、Java には存在しないため
  対象外。

## 付録: ExtractJavaProofState.v

`../zfcert/ExtractJavaProofState.v`(zfcert リポジトリ直下)が無い場合は以下を復元する
(出力先ディレクトリは適宜変更):

```coq
(* Java extraction entry point for ZFCert (experiment for proof-ninja/rocq#28).
   Mirrors coq/ExtractProofState.v minus the OCaml-specific parts
   (ExtrOcaml* imports and the string_of_int Extract Constant). *)
Require Corelib.extraction.Extraction.
From ZFCert Require Import
  ProofState TacticCompleteness ZFC NamedProofState NamedCommands
  CertifiedSession GlobalEnvironment.

Extraction Language Java.
Set Extraction Output Directory "/tmp/zfcert-java".
Extraction "zfcert.java"
  start_with_assumptions start state_goals
  step run rule_step rule_run
  named_start_with_environment
  named_start_with_constants named_start named_goals named_solved
  named_step named_run named_rule_step named_rule_run
  named_default_all_intro_rule_step
  named_fixed_axiom_rule_step
  named_separation_axiom_rule_step
  named_replacement_axiom_rule_step
  named_separation_tactic_step
  named_separation_term_tactic_step
  named_replacement_tactic_step
  named_execute_rule
  certified_start_with_environment
  certified_start_with_constants certified_start certified_goals certified_solved
  one_step certified_step certified_run
  certified_certificate
  replay_certificate_with_environment
  replay_certificate_with_constants replay_certificate certified_finalize
  certified_execute_rule
  certified_separation_tactic
  certified_separation_term_tactic
  certified_replacement_tactic
  empty_global_environment global_fact_names global_start global_replay
  global_declare_choice global_declare_fact global_declare_skolem
  empty_set_axiom extensionality_axiom pairing_axiom union_axiom
  power_set_axiom foundation_axiom infinity_axiom choice_axiom
  separation_instance replacement_instance.
```
