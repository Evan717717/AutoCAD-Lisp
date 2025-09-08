;;; ========================================
;;; Floor Export Tool - Basic Stable Version
;;; Version: 7.0 - 基礎穩定版
;;; ========================================

;;; 測試命令 - 最簡單的版本
(defun c:TEST1 ()
  (princ "\nTEST1 工作正常!")
  (princ)
)

;;; 測試變數設定
(defun c:TEST2 ()
  (setq test-var "測試變數")
  (princ (strcat "\nTEST2 工作正常! 變數值: " test-var))
  (princ)
)

;;; 測試系統變數
(defun c:TEST3 ()
  (princ "\nTEST3 - 系統變數測試:")
  (princ (strcat "\n當前圖檔路徑: " (getvar "DWGPREFIX")))
  (princ (strcat "\nOSMODE: " (itoa (getvar "OSMODE"))))
  (princ)
)

;;; ========================================
;;; 最簡單的輸出功能
;;; ========================================

(defun c:EX1 (/ pt1 pt2)
  (princ "\n===== 簡單輸出測試 =====")
  
  ;; 取得兩個點
  (setq pt1 (getpoint "\n第一個角點: "))
  
  (if pt1
    (progn
      (setq pt2 (getcorner pt1 "\n對角點: "))
      
      (if pt2
        (princ "\n成功取得兩個點!")
        (princ "\n取消選擇")
      )
    )
    (princ "\n取消選擇")
  )
  
  (princ)
)

;;; ========================================
;;; 選擇物件測試
;;; ========================================

(defun c:EX2 (/ pt1 pt2 ss)
  (princ "\n===== 選擇物件測試 =====")
  
  ;; 關閉物件鎖點
  (setvar "OSMODE" 0)
  
  ;; 取得兩個點
  (setq pt1 (getpoint "\n第一個角點: "))
  
  (if pt1
    (progn
      (setq pt2 (getcorner pt1 "\n對角點: "))
      
      (if pt2
        (progn
          ;; 選擇物件
          (setq ss (ssget "W" pt1 pt2))
          
          (if ss
            (princ (strcat "\n選取了 " (itoa (sslength ss)) " 個物件"))
            (princ "\n沒有選取到物件")
          )
        )
      )
    )
  )
  
  (princ)
)

;;; ========================================
;;; WBLOCK 測試 - 最基本版本
;;; ========================================

(defun c:EX3 (/ pt1 pt2 ss filename)
  (princ "\n===== WBLOCK 基本測試 =====")
  
  ;; 關閉物件鎖點
  (setvar "OSMODE" 0)
  
  ;; 固定檔名測試
  (setq filename (strcat (getvar "DWGPREFIX") "test_export.dwg"))
  (princ (strcat "\n將儲存至: " filename))
  
  ;; 取得兩個點
  (setq pt1 (getpoint "\n第一個角點: "))
  
  (if pt1
    (progn
      (setq pt2 (getcorner pt1 "\n對角點: "))
      
      (if pt2
        (progn
          ;; 選擇物件
          (setq ss (ssget "W" pt1 pt2))
          
          (if ss
            (progn
              (princ (strcat "\n選取了 " (itoa (sslength ss)) " 個物件"))
              
              ;; 嘗試 WBLOCK
              (command "_.WBLOCK" filename "" "0,0" ss "")
              
              (princ "\n執行 WBLOCK 完成")
            )
            (princ "\n沒有選取到物件")
          )
        )
      )
    )
  )
  
  (princ)
)

;;; ========================================
;;; 完整但簡化的輸出功能
;;; ========================================

(defun c:EXPORT (/ osmode-old pt1 pt2 ss filename base-pt)
  
  ;; 儲存並設定系統變數
  (setq osmode-old (getvar "OSMODE"))
  (setvar "OSMODE" 0)
  
  ;; 取得檔名
  (setq filename (getfiled "儲存 DWG 檔案" "" "dwg" 1))
  
  (if filename
    (progn
      ;; 選擇區域
      (princ "\n選擇要輸出的區域...")
      (setq pt1 (getpoint "\n第一個角點: "))
      
      (if pt1
        (progn
          (setq pt2 (getcorner pt1 "\n對角點: "))
          
          (if pt2
            (progn
              ;; 選擇物件
              (setq ss (ssget "W" pt1 pt2))
              
              (if ss
                (progn
                  (princ (strcat "\n輸出 " (itoa (sslength ss)) " 個物件..."))
                  
                  ;; 設定基準點
                  (setq base-pt (list 0 0 0))
                  
                  ;; 標記 UNDO
                  (command "_.UNDO" "_M")
                  
                  ;; 執行 WBLOCK
                  (command "_.WBLOCK" filename "" base-pt ss "")
                  
                  ;; 復原
                  (command "_.UNDO" "_B")
                  
                  (princ (strcat "\n完成! 檔案: " filename))
                )
                (princ "\n沒有選取到物件")
              )
            )
          )
        )
      )
    )
    (princ "\n取消")
  )
  
  ;; 還原系統變數
  (setvar "OSMODE" osmode-old)
  
  (princ)
)

;;; ========================================
;;; 載入訊息
;;; ========================================

(princ "\n========================================")
(princ "\n Floor Export Tool v7.0 - 基礎穩定版")
(princ "\n")
(princ "\n 測試命令:")
(princ "\n   TEST1  - 基本測試")
(princ "\n   TEST2  - 變數測試")
(princ "\n   TEST3  - 系統變數測試")
(princ "\n")
(princ "\n 功能命令:")
(princ "\n   EX1    - 點選測試")
(princ "\n   EX2    - 選擇物件測試")
(princ "\n   EX3    - WBLOCK測試")
(princ "\n   EXPORT - 完整輸出功能")
(princ "\n")
(princ "\n 請依序測試 TEST1, TEST2, TEST3")
(princ "\n========================================")
(princ)