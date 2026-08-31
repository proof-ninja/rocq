#!/bin/sh
# ZFCert Java 抽出の検証スクリプト (issue #28)。
# 抽出 → javac → ランタイム検証 (DriverZfcert) をワンコマンドで実行する。
# 手順の詳細と基準値は同ディレクトリの zfcert-verification.md を参照。
# 前提: fork の rocq が make world 済み、stdlib と zfcert が sibling に
# clone 済みで、zfcert の .vo がビルド済みであること(手順書のステップ 0〜2)。
set -eu

BASE=$(cd "$(dirname "$0")/../.." && pwd)   # この fork のルート
ROCQ=$BASE/_build/install/default/bin/rocq
STDLIB=$(dirname "$BASE")/stdlib/theories
ZFCERT=$(dirname "$BASE")/zfcert
OUT=/tmp/zfcert-java

for p in "$ROCQ" "$STDLIB" "$ZFCERT/coq/FOL.vo" "$ZFCERT/ExtractJavaProofState.v"; do
  if [ ! -e "$p" ]; then
    echo "missing: $p (zfcert-verification.md のステップ 0〜2 を先に実行)" >&2
    exit 1
  fi
done

mkdir -p "$OUT"
rm -f "$OUT"/zfcert.java "$OUT"/*.class

echo "== extraction =="
cd "$ZFCERT"
"$ROCQ" c -q -Q "$STDLIB" Stdlib -Q coq ZFCert ExtractJavaProofState.v 2>&1 \
  | grep -v -e deprecated-from-Coq -e "has been replaced" -e '^\[deprecated' || true
if [ ! -f "$OUT/zfcert.java" ]; then
  echo "NG: 抽出が zfcert.java を生成しませんでした" >&2
  exit 1
fi
wc -c "$OUT/zfcert.java"

echo "== javac =="
cd "$OUT"
if javac -Xmaxerrs 2000 zfcert.java 2> javac_errors.txt; then
  echo "OK: javac がエラーなしで通りました"
else
  total=$(grep -c "エラー:" javac_errors.txt || true)
  echo "NG: javac エラー $total 件 (基準値は 2026-08-27 時点で 921 件)"
  echo "-- 内訳 --"
  grep "エラー:" javac_errors.txt \
    | sed 's/zfcert.java:[0-9]*: //' | sort | uniq -c | sort -rn
  echo "-- 詳細: $OUT/javac_errors.txt --"
  exit 1
fi

echo "== runtime (DriverZfcert) =="
cp "$BASE/doc/java-extraction/DriverZfcert.java" "$OUT/"
javac zfcert.java DriverZfcert.java 2> driver_javac_errors.txt || {
  echo "NG: ドライバのコンパイルに失敗しました ($OUT/driver_javac_errors.txt)" >&2
  exit 1
}
if java DriverZfcert; then
  echo "OK: ランタイム検証が通りました"
else
  echo "NG: ランタイム検証が失敗しました" >&2
  exit 1
fi
