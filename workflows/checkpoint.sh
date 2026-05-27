# Signature: emFta2FyYQ==
#!/bin/bash
# ============================================================================
# CHECKPOINT.SH - Auto branch, stage, commit, dan push (GitHub & GitLab)
# ============================================================================
# Cara update script ini (untuk AI):
# 1. Jalankan `git diff` dan `git diff --cached` untuk melihat semua perubahan
# 2. Jalankan `git status` untuk melihat file baru (untracked)
# 3. Identifikasi fitur utama dan fix dari diff, buat judul branch format:
#    feat/APOLLO-{DDMMYYHHMM}-{judul-kecil-yang-mewakili-keseluruhan}
# 4. Update BRANCH_NAME di bawah dengan judul yang sesuai
# 5. Tulis commit message yang mencakup ringkasan dan detail
# 6. Simpan file, user tinggal jalankan ./checkpoint.sh
# ============================================================================

TIMESTAMP=$(date +"%d%m%y%H%M")

BRANCH_NAME="feat/APOLLO-${TIMESTAMP}-setup-checkpoint-script"

if git rev-parse --verify "$BRANCH_NAME" >/dev/null 2>&1; then
  git checkout "$BRANCH_NAME"
else
  git checkout -b "$BRANCH_NAME"
fi

git add -A

COMMIT_MSG=$(cat <<'EOF'
feat: tambah script auto-checkpoint untuk sinkronisasi GitHub dan GitLab

Perubahan utama:
- checkpoint.sh: script automasi untuk branch, commit, dan push ganda
- gitlab remote: menambahkan git@gitlab.com:zamkara/apollo.build.git sebagai target push kedua

Testing:
- [ ] Push berjalan sukses ke origin (GitHub)
- [ ] Push berjalan sukses ke gitlab (GitLab)
EOF
)

if git diff --cached --quiet; then
  echo ""
  echo "Branch ready: $(git branch --show-current)"
  echo "No staged changes to commit."
  exit 0
fi

git commit -m "$COMMIT_MSG"

echo ""
echo "Mendorong ke GitHub (origin)..."
git push -u origin "$BRANCH_NAME"

echo ""
echo "Mendorong ke GitLab (gitlab)..."
git push -u gitlab "$BRANCH_NAME"

echo ""
echo "Branch created: $BRANCH_NAME"
echo "Commit & Push successful to both repositories."
