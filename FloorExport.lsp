;;; ========================================
;;; Floor Export Tool - Memory Path Version
;;; Version: 6.0 - 記住上次儲存路徑
;;; ========================================

;;; 全域變數 - 儲存上次的路徑
(if (not *EXPORT-LAST-PATH*)
  (setq *EXPORT-LAST-PATH* nil)
)

;;; 全域變數 - 儲存常用路徑列表
(if (not *EXPORT-FAVORITE-PATHS*)
  (setq *EXPORT-FAVORITE-PATHS* nil)
)

;;; ========================================
;;; 主要輸出功能 - 記憶路徑版本
;;; ========================================

(defun c:EXPORTDWG (/ old-filedia old-osmode pt1 pt2 ss base-pt filename default-path)
  
  ;; Save system variables
  (setq old-filedia (getvar "FILEDIA"))
  (setq old-osmode (getvar "OSMODE"))
  
  ;; Set system variables
  (setvar "OSMODE" 0)
  (setvar "FILEDIA" 1)
  
  ;; 決定預設路徑
  (setq default-path 
    (cond
      ;; 如果有上次的路徑，使用上次的路徑
      (*EXPORT-LAST-PATH* *EXPORT-LAST-PATH*)
      ;; 否則使用當前圖檔路徑
      (t (getvar "DWGPREFIX"))
    )
  )
  
  ;; 切換到記憶的路徑
  (if (and default-path (vl-file-directory-p default-path))
    (progn
      (setvar "FILEDIA" 0)
      (vl-cmdf "_.FILEDIA" "0")
      (setvar "FILEDIA" 1)
      ;; 使用 getfiled 並指定路徑
      (setq filename (getfiled "儲存樓層平面圖" 
                              (strcat default-path "floor_plan") 
                              "dwg" 
                              1))
    )
    ;; 如果路徑無效，使用預設
    (setq filename (getfiled "儲存樓層平面圖" "" "dwg" 1))
  )
  
  (if filename
    (progn
      ;; 記住這次選擇的路徑
      (setq *EXPORT-LAST-PATH* (vl-filename-directory filename))
      
      ;; Step 2: Select area
      (princ "\n現在請選擇要輸出的區域...")
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
                  
                  ;; Use center of selection as base point
                  (setq base-pt (list
                    (/ (+ (car pt1) (car pt2)) 2.0)
                    (/ (+ (cadr pt1) (cadr pt2)) 2.0)
                    0.0
                  ))
                  
                  ;; IMPORTANT: Mark for UNDO to preserve original objects
                  (command "_.UNDO" "_Mark")
                  
                  ;; Step 4: Export using command line version
                  (setvar "FILEDIA" 0)  ; Turn off dialog for command
                  (command "_.WBLOCK" filename "" base-pt ss "")
                  
                  ;; IMPORTANT: Undo to restore original objects
                  (command "_.UNDO" "_Back")
                  
                  ;; Verify
                  (if (findfile filename)
                    (progn
                      (princ (strcat "\n[成功] 已儲存至: " filename))
                      (princ (strcat "\n[提示] 下次將預設使用路徑: " *EXPORT-LAST-PATH*))
                      (princ "\n[確認] 原始圖檔已保留")
                    )
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
;;; 快速切換常用路徑
;;; ========================================

(defun c:SETEXPORTPATH (/ new-path option path-list num)
  (princ "\n========== 設定輸出路徑 ==========")
  (princ (strcat "\n當前路徑: " (if *EXPORT-LAST-PATH* *EXPORT-LAST-PATH* "未設定")))
  (princ "\n")
  (princ "\n[1] 使用當前圖檔路徑")
  (princ "\n[2] 瀏覽選擇新路徑")
  (princ "\n[3] 直接輸入路徑")
  (princ "\n[C] 清除記憶路徑")
  (princ "\n")
  
  (initget "1 2 3 C")
  (setq option (getkword "\n選擇選項 [1/2/3/C]: "))
  
  (cond
    ((= option "1")
     (setq *EXPORT-LAST-PATH* (getvar "DWGPREFIX"))
     (princ (strcat "\n已設定為: " *EXPORT-LAST-PATH*)))
    
    ((= option "2")
     ;; 使用檔案對話框選擇任意檔案，然後取得其路徑
     (setq new-path (getfiled "選擇該資料夾中的任意檔案" "" "" 0))
     (if new-path
       (progn
         (setq *EXPORT-LAST-PATH* (vl-filename-directory new-path))
         (princ (strcat "\n已設定為: " *EXPORT-LAST-PATH*)))
       (princ "\n已取消")))
    
    ((= option "3")
     (setq new-path (getstring T "\n輸入完整路徑 (例: C:\\Projects\\Floor Plans\\): "))
     (if (vl-file-directory-p new-path)
       (progn
         (setq *EXPORT-LAST-PATH* new-path)
         (princ (strcat "\n已設定為: " *EXPORT-LAST-PATH*)))
       (princ "\n路徑無效!")))
    
    ((= option "C")
     (setq *EXPORT-LAST-PATH* nil)
     (princ "\n已清除記憶路徑"))
  )
  
  (princ)
)

;;; ========================================
;;; 快速輸出到上次路徑（無需選擇路徑）
;;; ========================================

(defun c:QEX (/ old-osmode pt1 pt2 ss base-pt filename floor-name timestamp)
  
  ;; Check if last path exists
  (if (not *EXPORT-LAST-PATH*)
    (progn
      (princ "\n[提示] 第一次使用，請先使用 EXPORTDWG 設定路徑")
      (princ "\n或使用 SETEXPORTPATH 命令設定預設路徑")
      (c:EXPORTDWG))
    (progn
      ;; Save and set variables
      (setq old-osmode (getvar "OSMODE"))
      (setvar "OSMODE" 0)
      
      ;; Show current path
      (princ (strcat "\n將儲存至: " *EXPORT-LAST-PATH*))
      
      ;; Get floor name for auto-naming
      (setq floor-name (getstring "\n樓層名稱 (1F/2F/B1 等): "))
      
      ;; Select area
      (princ "\n選擇要輸出的區域...")
      (setq pt1 (getpoint "\n第一個角點: "))
      
      (if pt1
        (progn
          (setq pt2 (getcorner pt1 "\n對角點: "))
          
          (if pt2
            (progn
              ;; Select objects
              (setq ss (ssget "W" pt1 pt2))
              
              (if (and ss (> (sslength ss) 0))
                (progn
                  (princ (strcat "\n已選取 " (itoa (sslength ss)) " 個物件"))
                  
                  ;; Set base point
                  (setq base-pt '(0 0 0))
                  
                  ;; Generate timestamp
                  (setq timestamp (menucmd "M=$(edtime,$(getvar,date),YYMODD_HHMMSS)"))
                  
                  ;; Auto-generate filename
                  (setq filename (strcat 
                    *EXPORT-LAST-PATH*
                    (if (not (wcmatch *EXPORT-LAST-PATH* "*[/\\]"))
                      "\\" "")
                    floor-name
                    "_"
                    timestamp
                    ".dwg"
                  ))
                  
                  ;; Mark for undo
                  (command "_.UNDO" "_Mark")
                  
                  ;; Export
                  (command "_.WBLOCK" filename "" base-pt ss "")
                  
                  ;; Restore objects
                  (command "_.UNDO" "_Back")
                  
                  ;; Check result
                  (if (findfile filename)
                    (princ (strcat "\n[成功] 已儲存: " (vl-filename-base filename) ".dwg"))
                    (princ "\n[錯誤] 輸出失敗"))
                )
                (princ "\n沒有選取到物件")
              )
            )
          )
        )
      )
      
      ;; Restore
      (setvar "OSMODE" old-osmode)
    )
  )
  
  (princ)
)

;;; ========================================
;;; 批次輸出（使用記憶路徑）
;;; ========================================

(defun c:BATCHEX (/ continue old-osmode pt1 pt2 ss base-pt filename floor-name count)
  
  ;; Check and set default path
  (if (not *EXPORT-LAST-PATH*)
    (setq *EXPORT-LAST-PATH* (getvar "DWGPREFIX"))
  )
  
  ;; Save variables
  (setq old-osmode (getvar "OSMODE"))
  (setvar "OSMODE" 0)
  (setq count 0)
  (setq continue T)
  
  (princ (strcat "\n批次輸出模式 - 預設路徑: " *EXPORT-LAST-PATH*))
  (princ "\n提示: 輸入檔名後選擇區域，直接按 Enter 結束")
  
  ;; Loop for multiple exports
  (while continue
    
    ;; Get filename
    (setq floor-name (getstring (strcat "\n檔案名稱 (不含.dwg) [Enter=結束]: ")))
    
    (if (and floor-name (not (= floor-name "")))
      (progn
        ;; Build full path
        (setq filename (strcat
          *EXPORT-LAST-PATH*
          (if (not (wcmatch *EXPORT-LAST-PATH* "*[/\\]"))
            "\\" "")
          floor-name
          ".dwg"
        ))
        
        ;; Select area
        (princ (strcat "\n選擇 \"" floor-name "\" 的區域..."))
        (setq pt1 (getpoint "\n第一個角點: "))
        
        (if pt1
          (progn
            (setq pt2 (getcorner pt1 "\n對角點: "))
            
            (if pt2
              (progn
                ;; Select and export
                (setq ss (ssget "W" pt1 pt2))
                
                (if ss
                  (progn
                    (setq base-pt '(0 0 0))
                    
                    ;; Mark for undo
                    (command "_.UNDO" "_Mark")
                    
                    ;; Export
                    (command "_.WBLOCK" filename "" base-pt ss "")
                    
                    ;; Restore objects
                    (command "_.UNDO" "_Back")
                    
                    (if (findfile filename)
                      (progn
                        (setq count (1+ count))
                        (princ (strcat "\n[成功] 已儲存: " floor-name ".dwg")))
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
      (setq continue nil)  ; User pressed Enter
    )
  )
  
  ;; Restore
  (setvar "OSMODE" old-osmode)
  
  (princ (strcat "\n批次輸出完成! 共輸出 " (itoa count) " 個檔案"))
  (princ "\n所有原始物件均已保留")
  (princ)
)

;;; ========================================
;;; 開啟上次儲存的資料夾
;;; ========================================

(defun c:OPENEXPORTFOLDER ()
  (if *EXPORT-LAST-PATH*
    (if (vl-file-directory-p *EXPORT-LAST-PATH*)
      (progn
        (startapp "explorer" *EXPORT-LAST-PATH*)
        (princ (strcat "\n已開啟: " *EXPORT-LAST-PATH*)))
      (princ "\n路徑不存在!"))
    (princ "\n尚未設定輸出路徑"))
  (princ)
)

;;; ========================================
;;; Loading message
;;; ========================================

(princ "\n========================================")
(princ "\nFloor Export Tool v6.0 - 記憶路徑版本")
(princ "\n")
(princ "\n主要命令:")
(princ "\n  EXPORTDWG  - 主要輸出功能（記憶路徑）")
(princ "\n  QEX        - 快速輸出（直接用上次路徑）")
(princ "\n  BATCHEX    - 批次輸出多個區域")
(princ "\n")
(princ "\n輔助命令:")
(princ "\n  SETEXPORTPATH     - 設定預設輸出路徑")
(princ "\n  OPENEXPORTFOLDER  - 開啟上次的輸出資料夾")
(princ "\n")
(princ "\n[新功能] 會自動記住上次選擇的路徑!")
(princ "\n[提示] 第一次使用時會使用當前圖檔路徑")
(princ "\n========================================")
(princ)