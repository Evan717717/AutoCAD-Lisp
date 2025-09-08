;;; ========================================
;;; Floor Export Tool - Complete Version with Path Memory
;;; Version: 8.0 - English Version
;;; ========================================

;;; Global variable to store last used path
(setq *EXPORT-LAST-PATH* nil)

;;; Global variable to store last used filename
(setq *EXPORT-LAST-NAME* "floor_plan")

;;; ========================================
;;; Main Export Function with Path Memory
;;; ========================================

(defun c:EX (/ old-filedia old-osmode old-expert pt1 pt2 ss base-pt filename default-file)
  
  ;; Save system variables
  (setq old-filedia (getvar "FILEDIA"))
  (setq old-osmode (getvar "OSMODE"))
  (setq old-expert (getvar "EXPERT"))
  
  ;; Set system variables
  (setvar "FILEDIA" 1)
  (setvar "OSMODE" 0)
  (setvar "EXPERT" 2)
  
  ;; Build default file path
  (if *EXPORT-LAST-PATH*
    ;; Use last path if available
    (setq default-file (strcat *EXPORT-LAST-PATH* "\\" *EXPORT-LAST-NAME*))
    ;; Otherwise use drawing path
    (setq default-file (strcat (getvar "DWGPREFIX") *EXPORT-LAST-NAME*))
  )
  
  ;; Get save location with default path
  (princ "\nSelect save location...")
  (setq filename (getfiled "Save floor plan as" default-file "dwg" 1))
  
  (if filename
    (progn
      ;; Store the path for next time
      (setq *EXPORT-LAST-PATH* (vl-filename-directory filename))
      (setq *EXPORT-LAST-NAME* (vl-filename-base filename))
      
      ;; Select area
      (princ "\nSelect area to export...")
      (setq pt1 (getpoint "\nFirst corner: "))
      
      (if pt1
        (progn
          (setq pt2 (getcorner pt1 "\nOpposite corner: "))
          
          (if pt2
            (progn
              ;; Select objects
              (setq ss (ssget "W" pt1 pt2))
              
              (if (and ss (> (sslength ss) 0))
                (progn
                  (princ (strcat "\nExporting " (itoa (sslength ss)) " objects..."))
                  
                  ;; Use first point as base
                  (setq base-pt pt1)
                  
                  ;; Mark for undo
                  (command "_.UNDO" "_Mark")
                  
                  ;; Execute WBLOCK
                  (setvar "FILEDIA" 0)
                  (command "_.WBLOCK" filename "" base-pt ss "")
                  
                  ;; Restore original objects
                  (command "_.UNDO" "_Back")
                  
                  ;; Report result
                  (if (findfile filename)
                    (progn
                      (princ (strcat "\n[OK] Saved to: " filename))
                      (princ (strcat "\n[INFO] Next default path: " *EXPORT-LAST-PATH*))
                    )
                    (princ "\n[ERROR] Export failed")
                  )
                )
                (princ "\nNo objects selected")
              )
            )
          )
        )
      )
    )
    (princ "\nCancelled")
  )
  
  ;; Restore system variables
  (setvar "FILEDIA" old-filedia)
  (setvar "OSMODE" old-osmode)
  (setvar "EXPERT" old-expert)
  
  (princ)
)

;;; ========================================
;;; Quick Export to Last Path
;;; ========================================

(defun c:QEX (/ old-osmode pt1 pt2 ss base-pt filename floor-name datetime)
  
  ;; Check if path exists
  (if (not *EXPORT-LAST-PATH*)
    (progn
      (princ "\n[INFO] First time use, please use EX command first")
      (c:EX))
    (progn
      ;; Save and set variables
      (setq old-osmode (getvar "OSMODE"))
      (setvar "OSMODE" 0)
      
      ;; Show current path
      (princ (strcat "\nWill save to: " *EXPORT-LAST-PATH*))
      
      ;; Get floor name
      (setq floor-name (getstring "\nEnter floor name (1F/2F/B1/etc): "))
      (if (= floor-name "") (setq floor-name "floor"))
      
      ;; Select area
      (princ "\nSelect area to export...")
      (setq pt1 (getpoint "\nFirst corner: "))
      
      (if pt1
        (progn
          (setq pt2 (getcorner pt1 "\nOpposite corner: "))
          
          (if pt2
            (progn
              ;; Select objects
              (setq ss (ssget "W" pt1 pt2))
              
              (if (and ss (> (sslength ss) 0))
                (progn
                  (princ (strcat "\nSelected " (itoa (sslength ss)) " objects"))
                  
                  ;; Set base point
                  (setq base-pt '(0 0 0))
                  
                  ;; Create datetime string
                  (setq datetime (menucmd "M=$(edtime,$(getvar,date),YYMMDD_HHMM)"))
                  
                  ;; Auto-generate filename
                  (setq filename (strcat 
                    *EXPORT-LAST-PATH*
                    "\\"
                    floor-name
                    "_"
                    datetime
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
                    (princ (strcat "\n[OK] Saved: " (vl-filename-base filename) ".dwg"))
                    (princ "\n[ERROR] Export failed")
                  )
                )
                (princ "\nNo objects selected")
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
;;; Batch Export with Memory Path
;;; ========================================

(defun c:BATCHEX (/ continue old-osmode pt1 pt2 ss base-pt filename floor-name count)
  
  ;; Set default path if not exists
  (if (not *EXPORT-LAST-PATH*)
    (setq *EXPORT-LAST-PATH* (getvar "DWGPREFIX"))
  )
  
  ;; Save variables
  (setq old-osmode (getvar "OSMODE"))
  (setvar "OSMODE" 0)
  (setq count 0)
  (setq continue T)
  
  (princ (strcat "\nBatch export mode - Path: " *EXPORT-LAST-PATH*))
  (princ "\nTip: Enter filename then select area, press Enter to finish")
  
  ;; Loop for multiple exports
  (while continue
    
    ;; Get filename
    (setq floor-name (getstring "\nFilename (without .dwg) [Enter=finish]: "))
    
    (if (and floor-name (not (= floor-name "")))
      (progn
        ;; Build full path
        (setq filename (strcat
          *EXPORT-LAST-PATH*
          "\\"
          floor-name
          ".dwg"
        ))
        
        ;; Select area
        (princ (strcat "\nSelect area for \"" floor-name "\"..."))
        (setq pt1 (getpoint "\nFirst corner: "))
        
        (if pt1
          (progn
            (setq pt2 (getcorner pt1 "\nOpposite corner: "))
            
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
                        (princ (strcat "\n[OK] Saved: " floor-name ".dwg"))
                      )
                      (princ "\n[ERROR] Failed")
                    )
                  )
                  (princ "\nNo objects selected")
                )
              )
            )
          )
        )
      )
      (setq continue nil)
    )
  )
  
  ;; Restore
  (setvar "OSMODE" old-osmode)
  
  (princ (strcat "\nBatch export finished! Total: " (itoa count) " files"))
  (princ "\nAll original objects preserved")
  (princ)
)

;;; ========================================
;;; Set Export Path
;;; ========================================

(defun c:SETPATH (/ new-path option)
  (princ "\n========== Set Export Path ==========")
  (princ (strcat "\nCurrent: " (if *EXPORT-LAST-PATH* *EXPORT-LAST-PATH* "Not set")))
  (princ "\n")
  (princ "\n[1] Use current drawing path")
  (princ "\n[2] Browse for folder")
  (princ "\n[3] Type path manually")
  (princ "\n[C] Clear saved path")
  (princ "\n")
  
  (initget "1 2 3 C")
  (setq option (getkword "\nSelect option [1/2/3/C]: "))
  
  (cond
    ;; Option 1: Use drawing path
    ((= option "1")
     (setq *EXPORT-LAST-PATH* (getvar "DWGPREFIX"))
     (princ (strcat "\nPath set to: " *EXPORT-LAST-PATH*)))
    
    ;; Option 2: Browse
    ((= option "2")
     (setq new-path (getfiled "Select any file in target folder" "" "" 0))
     (if new-path
       (progn
         (setq *EXPORT-LAST-PATH* (vl-filename-directory new-path))
         (princ (strcat "\nPath set to: " *EXPORT-LAST-PATH*)))
       (princ "\nCancelled")))
    
    ;; Option 3: Manual input
    ((= option "3")
     (setq new-path (getstring T "\nEnter full path: "))
     (if (vl-file-directory-p new-path)
       (progn
         (setq *EXPORT-LAST-PATH* new-path)
         (princ (strcat "\nPath set to: " *EXPORT-LAST-PATH*)))
       (princ "\nInvalid path!")))
    
    ;; Option C: Clear
    ((= option "C")
     (setq *EXPORT-LAST-PATH* nil)
     (princ "\nPath cleared"))
  )
  
  (princ)
)

;;; ========================================
;;; Open Export Folder
;;; ========================================

(defun c:OPENFOLDER ()
  (if *EXPORT-LAST-PATH*
    (if (vl-file-directory-p *EXPORT-LAST-PATH*)
      (progn
        (startapp "explorer" *EXPORT-LAST-PATH*)
        (princ (strcat "\nOpening: " *EXPORT-LAST-PATH*)))
      (princ "\nPath does not exist!"))
    (princ "\nNo path set yet"))
  (princ)
)

;;; ========================================
;;; Show Current Settings
;;; ========================================

(defun c:SHOWPATH ()
  (princ "\n========== Current Settings ==========")
  (princ (strcat "\nExport Path: " (if *EXPORT-LAST-PATH* *EXPORT-LAST-PATH* "Not set")))
  (princ (strcat "\nLast Name: " (if *EXPORT-LAST-NAME* *EXPORT-LAST-NAME* "floor_plan")))
  (princ (strcat "\nDrawing Path: " (getvar "DWGPREFIX")))
  (princ "\n======================================")
  (princ)
)

;;; ========================================
;;; Loading Message
;;; ========================================

(princ "\n========================================")
(princ "\n Floor Export Tool v8.0 - Path Memory")
(princ "\n")
(princ "\n Main Commands:")
(princ "\n   EX        - Export with dialog (remembers path)")
(princ "\n   QEX       - Quick export to last path")
(princ "\n   BATCHEX   - Batch export multiple areas")
(princ "\n")
(princ "\n Utility Commands:")
(princ "\n   SETPATH    - Set default export path")
(princ "\n   OPENFOLDER - Open last export folder")
(princ "\n   SHOWPATH   - Show current settings")
(princ "\n")
(princ "\n [NEW] Auto-remembers last used path!")
(princ "\n [TIP] Use EX first time, then QEX for speed")
(princ "\n========================================")
(princ)