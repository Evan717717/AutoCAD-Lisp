;;; ========================================
;;; Floor Export Tool - Fixed Version
;;; Version: 6.1 - 修正載入問題
;;; ========================================

;;; 確保載入 Visual LISP 功能
(vl-load-com)

;;; 全域變數 - 儲存上次的路徑
(if (not *EXPORT-LAST-PATH*)
  (setq *EXPORT-LAST-PATH* nil)
)

;;; ========================================
;;; 簡化版主要功能 - 確保能運作
;;; ========================================

(defun c:EX (/ old-filedia old-osmode pt1 pt2 ss base-pt filename)
  
  ;; Save system variables
  (setq old-filedia (getvar "FILEDIA"))
  (setq old-osmode (getvar "OSMODE"))
  
  ;; Set system variables
  (setvar "OSMODE" 0)
  (setvar "FILEDIA" 1)
  
  ;; Step 1: Get save location
  (princ "\n選擇儲存位置...")
  
  ;; 使用記憶路徑或當前路徑
  (if *EXPORT-LAST-PATH*
    (setq filename (getfiled "儲存樓層平面圖" 
                            (strcat *EXPORT-LAST-PATH* "\\floor") 
                            "dwg" 
                            1))
    (setq filename (getfiled "儲存樓層平面圖" "" "dwg" 1))
  )
  
  (if filename
    (progn
      ;; 記住路徑
      (setq *EXPORT-LAST-PATH* (vl-filename-directory filename))
      
      ;; Step 2: Select area
      (princ "\n選擇要輸出的區域...")
      (setq pt1 (getpoint "\n第一個角點: "))
      
      (if pt1
        (progn
          (setq pt2 (getcorner pt1 "\n對角點: "))
          
          (if pt2
            (progn
              ;; Step 3: Select objects
              (setq ss (ssget "W" pt1 pt2))
              
              (if (and ss (> (sslength ss) 0))
                (progn
                  (princ (strcat "\n正在輸出 " (itoa (sslength ss)) " 個物件..."))
                  
                  ;; Set base point at origin
                  (setq base-pt '(0 0 0))
                  
                  ;; Mark for undo
                  (command "_.UNDO" "_Mark")
                  
                  ;; Export
                  (setvar "FILEDIA" 0)
                  (command "_.WBLOCK" filename "" base-pt ss "")
                  
                  ;; Restore
                  (command "_.UNDO" "_Back")
                  
                  ;; Report
                  (if (findfile filename)
                    (princ (strcat "\n[成功] 已儲存至: " filename))
                    (princ "\n[錯誤] 輸出失敗")
                  )
                )
                (princ "\n沒有選取到物件")
              )
            )
          )
        )
      )
    )
    (princ "\n已取消")
  )
  
  ;; Restore
  (setvar "FILEDIA" old-filedia)
  (setvar "OSMODE" old-osmode)
  
  (princ)
)

;;; ========================================
;;; 測試命令 - 確認 LISP 是否載入
;;; ========================================

(defun c:TEST ()
  (princ "\n========================================")
  (princ "\nLISP 檔案已成功載入!")
  (princ "\n可用命令:")
  (princ "\n  TEST - 測試命令（現在執行中）")
  (princ "\n  EX   - 簡單輸出功能")
  (princ "\n  QEX  - 快速輸出")
  (princ "\n========================================")
  (princ)
)

;;; ========================================
;;; 快速輸出（簡化版）
;;; ========================================

(defun c:QEX (/ old-osmode pt1 pt2 ss base-pt filename floor-name)
  
  ;; Check path
  (if (not *EXPORT-LAST-PATH*)
    (setq *EXPORT-LAST-PATH* (getvar "DWGPREFIX"))
  )
  
  ;; Save variables
  (setq old-osmode (getvar "OSMODE"))
  (setvar "OSMODE" 0)
  
  ;; Show path
  (princ (strcat "\n將儲存至: " *EXPORT-LAST-PATH*))
  
  ;; Get name
  (setq floor-name (getstring "\n輸入檔名 (不含.dwg): "))
  
  (if (and floor-name (not (= floor-name "")))
    (progn
      ;; Select area
      (princ "\n選擇區域...")
      (setq pt1 (getpoint "\n第一個角點: "))
      
      (if pt1
        (progn
          (setq pt2 (getcorner pt1 "\n對角點: "))
          
          (if pt2
            (progn
              ;; Select
              (setq ss (ssget "W" pt1 pt2))
              
              (if ss
                (progn
                  ;; Build filename
                  (setq filename (strcat 
                    *EXPORT-LAST-PATH*
                    "\\"
                    floor-name
                    ".dwg"
                  ))
                  
                  ;; Base point
                  (setq base-pt '(0 0 0))
                  
                  ;; Export
                  (command "_.UNDO" "_Mark")
                  (command "_.WBLOCK" filename "" base-pt ss "")
                  (command "_.UNDO" "_Back")
                  
                  ;; Report
                  (if (findfile filename)
                    (princ (strcat "\n[成功] 已儲存: " floor-name ".dwg"))
                    (princ "\n[錯誤] 輸出失敗")
                  )
                )
                (princ "\n沒有選取到物件")
              )
            )
          )
        )
      )
    )
  )
  
  ;; Restore
  (setvar "OSMODE" old-osmode)
  (princ)
)

;;; ========================================
;;; 設定路徑
;;; ========================================

(defun c:SETPATH ()
  (princ "\n========== 設定輸出路徑 ==========")
  (princ (strcat "\n當前: " (if *EXPORT-LAST-PATH* *EXPORT-LAST-PATH* "未設定")))
  
  (setq *EXPORT-LAST-PATH* 
    (getstring T "\n輸入新路徑 (或 Enter 使用當前圖檔路徑): "))
  
  (if (= *EXPORT-LAST-PATH* "")
    (setq *EXPORT-LAST-PATH* (getvar "DWGPREFIX"))
  )
  
  (princ (strcat "\n已設定為: " *EXPORT-LAST-PATH*))
  (princ)
)

;;; ========================================
;;; 開啟資料夾
;;; ========================================

(defun c:OPENFOLDER ()
  (if *EXPORT-LAST-PATH*
    (progn
      (startapp "explorer" *EXPORT-LAST-PATH*)
      (princ (strcat "\n開啟: " *EXPORT-LAST-PATH*))
    )
    (princ "\n尚未設定路徑")
  )
  (princ)
)

;;; ========================================
;;; 載入時顯示訊息
;;; ========================================

(princ "\n========================================")
(princ "\nFloor Export Tool v6.1 - 修正版")
(princ "\n")
(princ "\n可用命令:")
(princ "\n  TEST       - 測試載入狀態")
(princ "\n  EX         - 主要輸出功能")
(princ "\n  QEX        - 快速輸出")
(princ "\n  SETPATH    - 設定預設路徑")
(princ "\n  OPENFOLDER - 開啟輸出資料夾")
(princ "\n")
(princ "\n請先輸入 TEST 確認載入成功")
(princ "\n========================================")
(princ)