function fix_finite,image

;image2=image
;image(where(finite(image) eq 0))=0.
ind = where(finite(image) eq 0,/null)
if ind ne !null then image(ind)=0.

return,image
end
