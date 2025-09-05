;;; ========================================
;;; Floor Export Tool - Streamlined Version
;;; Version: 5.0 - Simple & Integrated
;;; ========================================

(defun c:EX (/ old-filedia old-osmode old-expert pt1 pt2 ss base-pt)
  
  ;; Save system variables
  (setq old-filedia (getvar "FILEDIA"))
  (setq old-osmode (getvar "OSMODE"))
  (setq old-expert (getvar "EXPERT"))
  
  ;; Set system variables
  (setvar "FILEDIA" 1)   ; Enable file dialog
  (setvar "OSMODE" 0)    ; Turn off object snap
  (setvar "EXPERT" 2)    ; Suppress some prompts
  
  ;; Step 1: Prompt for selection area
  (princ "\nSelect area to export...")
  (setq pt1 (getpoint "\nFirst corner: "))
  
  (if pt1
    (progn
      ;; Get opposite corner
      (setq pt2 (getcorner pt1 "\nOpposite corner: "))
      
      (if pt2
        (progn
          ;; Step 2: Select objects in window
          (setq ss (ssget "W" pt1 pt2))
          
          (if (and ss (> (sslength ss) 0))
            (progn
              ;; Show selection count
              (princ (strcat "\nSelected " (itoa (sslength ss)) " objects"))
              
              ;; Use first corner as base point
              (setq base-pt pt1)
              
              ;; Step 3: Execute WBLOCK with dialog
              ;; This will open the save dialog automatically
              (princ "\nChoose location and filename in the dialog...")
              
              ;; Mark for undo
              (command "_.UNDO" "_Mark")
              
              (command "_.WBLOCK")
              ;; The dialog will appear here
              ;; User selects path and enters filename
              
              ;; After dialog closes, continue with the command
              (if (> (getvar "CMDACTIVE") 0)
                (progn
                  (command "")      ; No block name
                  (command base-pt) ; Base point
                  (command ss)      ; Selection set
                  (command "")      ; End selection
                )
              )
              
              ;; Restore original objects
              (command "_.UNDO" "_Back")
              
              (princ "\n[OK] Export completed! Original objects preserved.")
            )
            (princ "\nNo objects selected in the area")
          )
        )
        (princ "\nSelection cancelled")
      )
    )
    (princ "\nSelection cancelled")
  )
  
  ;; Restore system variables
  (setvar "FILEDIA" old-filedia)
  (setvar "OSMODE" old-osmode)
  (setvar "EXPERT" old-expert)
  
  (princ)
)

;;; ========================================
;;; Alternative version with more control
;;; ========================================

(defun c:EXPORTDWG (/ old-filedia old-osmode pt1 pt2 ss base-pt filename ss-copy)
  
  ;; Save system variables
  (setq old-filedia (getvar "FILEDIA"))
  (setq old-osmode (getvar "OSMODE"))
  
  ;; Set system variables
  (setvar "OSMODE" 0)
  
  ;; Step 1: Get filename and path using dialog
  (setvar "FILEDIA" 1)
  (setq filename (getfiled "Save floor plan as" "" "dwg" 1))
  
  (if filename
    (progn
      ;; Step 2: Select area
      (princ "\nNow select the area to export...")
      (setq pt1 (getpoint "\nFirst corner: "))
      
      (if pt1
        (progn
          (setq pt2 (getcorner pt1 "\nOpposite corner: "))
          
          (if pt2
            (progn
              ;; Step 3: Select objects
              (setq ss (ssget "W" pt1 pt2))
              
              (if (and ss (> (sslength ss) 0))
                (progn
                  (princ (strcat "\nExporting " (itoa (sslength ss)) " objects..."))
                  
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
                      (princ (strcat "\n[OK] Saved to: " filename))
                      (princ "\n[OK] Original drawing preserved")
                      ;; Optional: Open folder
                      (initget "Y N")
                      (if (= "Y" (getkword "\nOpen folder? [Y/N] <N>: "))
                        (startapp "explorer" (vl-filename-directory filename))
                      )
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
  
  ;; Restore
  (setvar "FILEDIA" old-filedia)
  (setvar "OSMODE" old-osmode)
  
  (princ)
)

;;; ========================================
;;; Quick export with auto-naming
;;; ========================================

(defun c:QEX (/ old-osmode pt1 pt2 ss base-pt filepath filename floor-name)
  
  ;; Save and set variables
  (setq old-osmode (getvar "OSMODE"))
  (setvar "OSMODE" 0)
  
  ;; Get floor name for auto-naming
  (setq floor-name (getstring "\nFloor name (1F/2F/B1 etc.): "))
  
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
              
              ;; Auto-generate filename with timestamp
              (setq filename (strcat 
                (getvar "DWGPREFIX")
                floor-name
                "_"
                (menucmd "M=$(edtime,$(getvar,date),YYMODD-HHMMSS)")
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
                (princ (strcat "\n[OK] Saved as: " filename))
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
  
  (princ)
)

;;; ========================================
;;; Batch export with custom names
;;; ========================================

(defun c:BATCHEX (/ continue old-osmode pt1 pt2 ss base-pt filename)
  
  ;; Save variables
  (setq old-osmode (getvar "OSMODE"))
  (setvar "OSMODE" 0)
  
  (setq continue T)
  
  ;; Loop for multiple exports
  (while continue
    
    ;; Get filename first
    (setq filename (getfiled "Save as (or Cancel to finish)" "" "dwg" 1))
    
    (if filename
      (progn
        ;; Select area
        (princ "\nSelect area for this file...")
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
                      (princ (strcat "\n[OK] Saved: " (vl-filename-base filename) ".dwg"))
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
      (setq continue nil)  ; User cancelled file dialog
    )
  )
  
  ;; Restore
  (setvar "OSMODE" old-osmode)
  
  (princ "\nBatch export finished! All original objects preserved.")
  (princ)
)

;;; ========================================
;;; Loading message
;;; ========================================

(princ "\n========================================")
(princ "\nFloor Export Tool v5.1 - Fixed Version")
(princ "\n")
(princ "\nCommands:")
(princ "\n  EXPORTDWG  - Export with file dialog (recommended)")
(princ "\n  EX         - Simple export")
(princ "\n  QEX        - Quick export with auto-name")
(princ "\n  BATCHEX    - Batch export multiple areas")
(princ "\n")
(princ "\n[FIXED] Original objects are now preserved!")
(princ "\nUsage: Type EXPORTDWG, choose save location, select area")
(princ "\n========================================")
(princ)