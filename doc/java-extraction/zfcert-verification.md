# ZFCert Java 抽出の検証手順

issue #28 (https://github.com/proof-ninja/rocq/issues/28) の検証手順書。
sub-issue (#31, #32, ...) を修正するたびにこの手順を再実行し、javac エラーが
期待通り減っているか(最終的にはゼロになるか)を確認する。

ワンコマンド版: このディレクトリの [`zfcert-check.sh`](./zfcert-check.sh) が
下記のステップ 3〜5(抽出 → javac → ランタイム検証)を自動実行する
(前提: ステップ 0〜2 が済んでいること)。

```sh
doc/java-extraction/zfcert-check.sh
```

## 前提となる配置

| パス | 内容 |
|------|------|
| `~/src/proofninja/rocq` | この fork。`make world` でビルド済みであること |
| `~/src/proofninja/stdlib` | rocq-prover/stdlib。fork の rocq でビルド済みであること |
| `~/src/proofninja/zfcert` | mir-ikbch/zfcert の clone |

## 0. 初回のみ: リポジトリの取得

```sh
git clone https://github.com/mir-ikbch/zfcert ~/src/proofninja/zfcert
git clone https://github.com/rocq-prover/stdlib ~/src/proofninja/stdlib
```

## 1. 初回のみ: Stdlib のビルド

ZFCert は Stdlib(`List` / `PeanoNat` / `String` / `Bool` / `DecimalString`)に
依存する。fork のビルドには Corelib しか入っていないため(Rocq 9 で Stdlib は
本体から分離された)、**fork の rocq で** Stdlib をビルドする必要がある。

```sh
cd ~/src/proofninja/stdlib
PATH=~/src/proofninja/rocq/_build/install/default/bin:$PATH make -j"$(nproc)"
```

- 2026-08-27 時点の stdlib master は fork (9.3+alpha) でそのまま全ビルドできる。
  ビルドが通らなくなったら、fork のベース時期に近い stdlib のコミットに checkout
  し直す(バージョン不整合はデバッグ対象ではない)。
- `make install` は**使わない**。インストール先の `_build/install/default` は
  fork の `make world` で再生成されて消えるため。参照は常に
  `-Q ~/src/proofninja/stdlib/theories Stdlib` で行う。
- fork の rocq を再ビルドしても、kernel のインターフェースが変わらない限り
  stdlib の .vo はそのまま使い回せる。`Compiled library ... makes inconsistent
  assumptions` 系のエラーが出たら stdlib を `make clean && make` し直す。

## 2. ZFCert の Coq ソースのコンパイル

java.ml の修正だけなら .vo は変わらないので再実行不要。fork の rocq を
再ビルドした直後や初回のみ:

```sh
cd ~/src/proofninja/zfcert
ROCQ=~/src/proofninja/rocq/_build/install/default/bin/rocq
for f in FOL ZFC ProofState TacticCompleteness NamedProofState NamedCommands \
         CertifiedSession GlobalEnvironment Audit; do
  $ROCQ c -q -Q ~/src/proofninja/stdlib/theories Stdlib -Q coq ZFCert coq/$f.v || break
done
```

- 全 9 ファイルが通ること。`From Coq` の deprecation 警告は無害。

## 3. Java 抽出

抽出エントリポイントは `~/src/proofninja/zfcert/ExtractJavaProofState.v`
(zfcert リポジトリ直下、untracked)。消えていた場合は本書末尾の付録から復元する。
これは `coq/ExtractProofState.v` から OCaml 専用部分(`ExtrOcaml*` の import と
`Extract Constant nat_to_decimal_string`)を除き、出力先と言語を Java に変えた
もので、**抽出対象の 50 定義のリストは同一**。

```sh
cd ~/src/proofninja/zfcert
OUT=/tmp/zfcert-java   # 出力先は任意
mkdir -p $OUT
$ROCQ c -q -Q ~/src/proofninja/stdlib/theories Stdlib -Q coq ZFCert \
  ExtractJavaProofState.v
```

※ 出力先は `ExtractJavaProofState.v` 内の `Set Extraction Output Directory` で
指定されている。変えたい場合はそこを書き換える。

**期待**: 抽出コマンド自体はエラーなしで完走し、`zfcert.java`(約 476KB)が
生成される。抽出段階のエラーは新規バグとして扱う。

## 4. javac によるコンパイル

```sh
cd <出力先>
javac -Xmaxerrs 2000 zfcert.java 2> javac_errors.txt
rg -c "エラー:" javac_errors.txt          # 総エラー数
rg "エラー:" javac_errors.txt | sed 's/zfcert.java:[0-9]*: //' | sort | uniq -c | sort -rn
```

### 基準値 (2026-08-27, feat/java-dtype = 99718f15a8 時点)

総エラー数 **921**。内訳:

| 件数 | エラー | 原因 |
|-----|--------|------|
| 400 | `java.lang.String を zfcert.String に変換できません` | #31 (String シャドウイング) |
| 352 | `シンボルを見つけられません`(全て Record のコンストラクタ名) | #32 (Record 不整合) |
| 86 | `Object を list に変換できません` | #32 の波及 |
| 60 | `条件式の型が不正です` | #32 の波及 |
| 21 | `Object を formula / named_formula に変換できません` | #32 の波及 |
| 1 | `RuntimeException に適切なコンストラクタが見つかりません` | #31 |
| 1 | `ラムダ式の戻り型が不正です` | 未分類(#31/#32 修正後に再判定) |

- **#31 修正後の期待**: `String` 系の 401 件が消える。
  → **実測済み (2026-08-27, fix/java-string-shadow + feat/java-dtype の合流ビルド)**:
  921 → **520** 件。String 系は全滅し、残りは全て #32 系。
  注意: Dtype 対応(PR #27)を含まないビルドでは型シノニムが裸の `type` トークンとして
  出力されて**構文エラー 2 件**になり、javac が意味解析に進まないため件数比較ができない。
  #31 以降の測定は PR #27 を含むビルドで行うこと。
- **#32 修正後の期待**: 未解決シンボル 352 件と `Object を〜に変換できません` 系の
  波及が消える。残ったエラーが「独立したキャスト漏れ」の候補であり、第 2 ラウンド
  として分類・issue 化する。
  → **実測済み (2026-08-27, #27+#31+#32 の合流ビルド)**: 520 → **0 件、javac 通過**。
  独立したキャスト漏れは存在しなかった(「条件式の型が不正」等も全て record 波及)。
  以後の回帰基準は「javac エラーゼロ」。次はステップ 5(ランタイム検証)へ。
- **最終ゴール**: javac がエラーゼロで通り、その後ランタイム検証(簡単なドライバで
  `start` → `step` 等を駆動)に進む。

## 5. ランタイム検証

ドライバは同ディレクトリの [`DriverZfcert.java`](./DriverZfcert.java)。
ZFCert の `src/self_test.ml` の抽出カーネル駆動部
(`Zfcert_kernel.start_with_constants` → `rule_step` → `solved` → `finalize`)を
Java に移植したもので、named formula を直接構築して certified セッションを駆動する。

```sh
cd /tmp/zfcert-java   # 抽出出力先
cp <fork>/doc/java-extraction/DriverZfcert.java .
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

- **実測 (2026-09-01, PR #34 マージ後の java_extraction ビルド)**: 全 12 チェック成功。
  「All 12 runtime checks passed.」が出れば OK。以後の回帰基準は
  「javac エラーゼロ + ランタイム検証全パス」(`zfcert-check.sh` が両方を検査する)。
- 対象範囲: 抽出カーネル(certified セッション)のみ。`.zfp` サンプルの実行には
  OCaml 側の表層パーサ(`Proof_session` / `Parser`)が必要で、Java には存在しないため
  対象外。

## 付録: ExtractJavaProofState.v

`~/src/proofninja/zfcert/ExtractJavaProofState.v` が無い場合は以下を復元する
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
