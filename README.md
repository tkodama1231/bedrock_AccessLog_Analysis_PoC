# Terraform セットアップ手順

このリポジトリでは、AWS Bedrock のアクセスログ解析環境を Terraform で構築します。  
以下の手順に従ってセットアップしてください。

---

## 1. リポジトリをクローン
```bash
git clone https://github.com/tkodama1231/bedrock_AccessLog_Analysis_PoC.git
cd bedrock_AccessLog_Analysis_PoC
```

---

## 2. `terraform.tfvars` の作成
`bedrock_AccessLog_Analysis_PoC` ディレクトリ配下に **terraform.tfvars** を作成し、Slack 通知用 Webhook URL を記載します。

```hcl
slack_webhook_url = "{SlackのWebhook URL}"
```

---

## 3. Terraform の初期化
```bash
terraform init
```

---

## 4. Terraform の適用
```bash
terraform apply
```

---

## 5. サンプルデータの準備
[zed-sample-data](https://github.com/brimdata/zed-sample-data/tree/main) から  
`http.json.gz` をダウンロードし、解凍します。

```bash
gunzip http.json.gz
```

---

## 6. S3 へのアップロード
解凍して得られた `http.json` を、Terraform で作成した S3 バケットにアップロードします。

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
aws s3 cp http.json s3://zeek-logs-bucket-poc-${ACCOUNT_ID}/
```

---

## 参考リンク
構築の背景や詳細解説は、[筆者ブログ](https://frafra-tekuteku.com/bedrock%e3%82%92%e6%b4%bb%e7%94%a8%e3%81%97%e3%81%9f%e3%82%a2%e3%82%af%e3%82%bb%e3%82%b9%e3%83%ad%e3%82%b0%e5%88%86%e6%9e%90/156/)でも紹介しています。
