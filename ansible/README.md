#  Linux 資安防護套件自動部署 

以 **Ansible** 為基礎的自動化腳本，適用於部署在 Linux 主機上，快速完成資安防護設定，包含：

-  安裝並啟用 CrowdStrike Falcon Sensor（MDR）
-  安裝 ESET Server Security 並啟用防護服務
-  校正 NTP 時間服務
-  停用不必要服務（如 GUI）
-  套用 SELinux Policy、啟用授權與狀態查詢
-  顯示已啟動防護的服務與版本資訊

將重複性執行任務，透過Ansible腳本快速安裝，以降低手動操作會有的耗時及失誤可能。

---

## 結構

```bash
.
├── hosts                         # Ansible inventory file (未放置於此)
├── playbook.yml                  # 主 playbook 腳本
├── installers/                   # 防毒安裝包（未放置於此）
├── playbook-screenshot-1.png    # 截圖：將安裝檔置入連線主機中，並確認是否已安裝ESET，若無則繼續安裝ESET
├── playbook-screenshot-2.png    # 截圖：上ESET授權、安裝EDR軟體、設定NTP Server
├── playbook-screenshot-3.png    # 截圖：確認NTP Server狀態是否符合預期並結束任務。
└── README.md                     # 說明文件
