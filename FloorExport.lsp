;;; ========================================
;;; Floor Export Tool - Complete Version v9.1
;;; Syntax corrected and verified.
;;; ========================================

;;; Global variable to store last used path
(setq *EXPORT-LAST-PATH* nil)

;;; Global variable to store last used filename
(setq *EXPORT-LAST-NAME* "floor_plan")

;;; Global variables for QEX system/floor/version
(setq *EXPORT-LAST-SYSTEM* "EE")
(setq *EXPORT-LAST-FLOOR* "1F")
(setq *EXPORT-LAST-VERSION* "v1")

;;; ========================================
;;; Main Export Function with Path Memory
;;; ========================================

(defun c:EXDWG (/ old-filedia old-osmode old-expert pt1 pt2 ss base-pt filename default-file)
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
;;; Quick Export with System-Floor-Version
;;; ========================================

(defun c:QEX (/ old-osmode pt1 pt2 ss base-pt filename system-name floor-name version-num version-choice overwrite)
  
  ;; Check if path exists
  (if (not *EXPORT-LAST-PATH*)
    (progn
      (princ "\n[INFO] First time use, please use EXDWG command first")
      (c:EXDWG))
    (progn
      ;; Save and set variables
      (setq old-osmode (getvar "OSMODE"))
      (setvar "OSMODE" 0)
      
      ;; Show current path
      (princ (strcat "\nWill save to: " *EXPORT-LAST-PATH*))
      (princ "\n")
      
      ;; Get system name
      (setq system-name (getstring (strcat "\nEnter system (EE/ME/ARCH/etc) <" *EXPORT-LAST-SYSTEM* ">: ")))
      (if (= system-name "") 
        (setq system-name *EXPORT-LAST-SYSTEM*)
        (setq *EXPORT-LAST-SYSTEM* system-name))
      
      ;; Get floor name
      (setq floor-name (getstring (strcat "\nEnter floor (1F/2F/B1/RF/etc) <" *EXPORT-LAST-FLOOR* ">: ")))
      (if (= floor-name "") 
        (setq floor-name *EXPORT-LAST-FLOOR*)
        (setq *EXPORT-LAST-FLOOR* floor-name))
      
      ;; Get version with menu
      (princ "\nSelect version:")
      (princ "\n  [1] v1 - Version 1")
      (princ "\n  [2] v2 - Version 2") 
      (princ "\n  [3] v3 - Version 3")
      (princ "\n  [4] v4 - Version 4")
      (princ "\n  [5] v5 - Version 5")
      (princ "\n  [0] v0 - Draft")
      (princ "\n  [C] Custom version")
      
      (initget "1 2 3 4 5 0 C")
      (setq version-choice (getkword (strcat "\nVersion [1/2/3/4/5/0/C] <" *EXPORT-LAST-VERSION* ">: ")))
      
      ;; Process version choice
      (cond
        ((= version-choice "0") (setq version-num "v0"))
        ((= version-choice "2") (setq version-num "v2"))
        ((= version-choice "3") (setq version-num "v3"))
        ((= version-choice "4") (setq version-num "v4"))
        ((= version-choice "5") (setq version-num "v5"))
        ((= version-choice "C") 
         (setq version-num (getstring "\nEnter custom version (e.g., vA, vFinal): "))
         (if (= version-num "") (setq version-num *EXPORT-LAST-VERSION*)))
        ((or (= version-choice "1") (= version-choice nil)) (setq version-num "v1")) ; Default to v1
        (T (setq version-num *EXPORT-LAST-VERSION*)) ; Keep last if user inputs something invalid
      )
      
      ;; Save version
      (setq *EXPORT-LAST-VERSION* version-num)
      
      ;; Show filename preview
      (princ (strcat "\nFilename will be: " system-name "-" floor-name "-" version-num ".dwg"))
      
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
                  
                  ;; Generate filename: SYSTEM-FLOOR-VERSION.dwg
                  (setq filename (strcat 
                    *EXPORT-LAST-PATH*
                    "\\"
                    system-name
                    "-"
                    floor-name
                    "-"
                    version-num
                    ".dwg"
                  ))
                  
                  ;; Check if file exists
                  (if (findfile filename)
                    (progn
                      (princ (strcat "\n[WARNING] File exists: " (vl-filename-base filename) ".dwg"))
                      (initget "Y N")
                      (setq overwrite (getkword "\nOverwrite? [Y/N] <N>: "))
                      (if (not (or (= overwrite "Y") (= overwrite "y")))
                        (setq filename nil)
                      )
                    )
                  )
                  
                  (if filename
                    (progn
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
                    (princ "\n[CANCELLED] Export cancelled")
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
;;; Quick Export Repeat - Same settings, different area
;;; ========================================

(defun c:QEXR (/ old-osmode pt1 pt2 ss base-pt filename overwrite)
  
  ;; Check if we have previous settings
  (if (not *EXPORT-LAST-PATH*)
    (progn
      (princ "\n[INFO] Please use QEX or EXDWG command first to set initial values")
      (c:QEX))
    (progn
      ;; Save and set variables
      (setq old-osmode (getvar "OSMODE"))
      (setvar "OSMODE" 0)
      
      ;; Show current settings
      (princ "\n========== Quick Export Repeat ==========")
      (princ (strcat "\nPath: " *EXPORT-LAST-PATH*))
      (princ (strcat "\nSystem: " *EXPORT-LAST-SYSTEM*))
      (princ (strcat "\nFloor: " *EXPORT-LAST-FLOOR*))
      (princ (strcat "\nVersion: " *EXPORT-LAST-VERSION*))
      (princ (strcat "\nFilename: " *EXPORT-LAST-SYSTEM* "-" *EXPORT-LAST-FLOOR* "-" *EXPORT-LAST-VERSION* ".dwg"))
      (princ "\n=========================================")
      
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
                  
                  ;; Generate filename
                  (setq filename (strcat 
                    *EXPORT-LAST-PATH*
                    "\\"
                    *EXPORT-LAST-SYSTEM*
                    "-"
                    *EXPORT-LAST-FLOOR*
                    "-"
                    *EXPORT-LAST-VERSION*
                    ".dwg"
                  ))
                  
                  ;; Check if file exists
                  (if (findfile filename)
                    (progn
                      (princ (strcat "\n[WARNING] File exists: " (vl-filename-base filename) ".dwg"))
                      (initget "Y N")
                      (setq overwrite (getkword "\nOverwrite? [Y/N] <N>: "))
                      (if (not (or (= overwrite "Y") (= overwrite "y")))
                        (setq filename nil)
                      )
                    )
                  )
                  
                  (if filename
                    (progn
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
                    (princ "\n[CANCELLED] Export cancelled")
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
     (setq new-path (getfiled "Select any file in target folder" "" "" 8))
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
  (princ (strcat "\nLast System: " *EXPORT-LAST-SYSTEM*))
  (princ (strcat "\nLast Floor: " *EXPORT-LAST-FLOOR*))
  (princ (strcat "\nLast Version: " *EXPORT-LAST-VERSION*))
  (princ (strcat "\nNext filename: " *EXPORT-LAST-SYSTEM* "-" *EXPORT-LAST-FLOOR* "-" *EXPORT-LAST-VERSION* ".dwg"))
  (princ (strcat "\nDrawing Path: " (getvar "DWGPREFIX")))
  (princ "\n======================================")
  (princ)
)

;;; ========================================
;;; Loading Message
;;; ========================================

(princ "\n========================================")
(princ "\n Floor Export Tool v9.1 - Complete")
(princ "\n")
(princ "\n Main Commands:")
(princ "\n   EXDWG      - Export with dialog (remembers path)")
(princ "\n   QEX        - Quick export (System-Floor-Version)")
(princ "\n   QEXR       - Repeat last QEX settings")
(princ "\n   BATCHEX    - Batch export multiple areas")
(princ "\n")
(princ "\n Utility Commands:")
(princ "\n   SETPATH    - Set default export path")
(princ "\n   OPENFOLDER - Open last export folder")
(princ "\n   SHOWPATH   - Show current settings")
(princ "\n")
(princ "\n [NEW] QEX uses System-Floor-Version naming!")
(princ "\n       Example: EE-2F-v1.dwg")
(princ "\n [TIP] Use QEXR to repeat with same settings")
(princ "\n========================================")
(princ)