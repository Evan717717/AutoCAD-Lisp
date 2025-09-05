;; =======================================================================
;; FixBigFont.lsp (Corrected Version)
;;
;; Purpose: Iterates through all text styles in the current drawing
;;          and forcefully changes their assigned Big Font file to "chineset.shx".
;;          This is used to repair drawings with corrupt or missing Big Font definitions.
;;
;; AutoCAD Version: All
;; Author: BIM Development
;;
;; To Use: 1. Load this file using the APPLOAD command.
;;         2. Type the new command "FIXBIGFONT" in the command line.
;; =======================================================================

(defun c:FIXBIGFONT (/ acadObj doc styles style styleName bigFontFile)
  ;; Load the ActiveX/COM libraries for LISP
  (vl-load-com)
  
  ;; Get the active AutoCAD application and document objects
  (setq acadObj (vlax-get-acad-object))
  (setq doc (vla-get-activedocument acadObj))
  
  ;; Get the collection of all Text Styles from the drawing
  (setq styles (vla-get-textstyles doc))

  ;; Print a starting message to the command line
  (princ "\nStarting batch process to fix Big Fonts in Text Styles...")

  ;; Loop through each style in the collection
  (vlax-for style styles
    (progn
      ;; Get the Big Font file assigned to the style.
      ;; The following line is the corrected logic.
      (setq bigFontFile (vla-get-bigfontfile style))
      
      ;; Check if the Big Font filename is not an empty string ("").
      ;; If it's not empty, it means a Big Font is supposed to be in use.
      (if (/= bigFontFile "")
        (progn
          ;; Get the style's name for the report
          (setq styleName (vla-get-name style))
          
          ;; Forcefully set its Big Font file to "chineset.shx"
          (vla-put-bigfontfile style "chineset.shx")
          
          ;; Print the name of the style that was fixed
          (princ (strcat "\nFixed Style: " styleName))
        )
      )
    )
  )
  
  ;; Regenerate the drawing to reflect the font changes
  (vla-regen doc acallviewports)
  
  ;; Print a final completion message
  (princ "\n...All styles using Big Fonts have been successfully repaired!")
  
  ;; Suppress the return value of the last function for a clean exit
  (princ)
)