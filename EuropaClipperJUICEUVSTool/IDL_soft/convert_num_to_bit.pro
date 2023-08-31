pro convert_num_to_bit, num_in, bit_out, nbit = nbit


  ; num_in : num number to be translated into bit
  ; bit_out : Output string translated from the input hexadecimal
  ; 
  ; Vincent Hue, SwRI, 2016
  ; input = 50112.

  bit_out = []
  n_input = fix(size(num_in, /n_elements))
  if not keyword_set(nbit) then nbit = 100
  
  for i_in = 0,n_input-1 do begin
    
    in = long(num_in[i_in])
    out=bytarr(nbit)
    for i = 0,nbit-1 do begin
      out[nbit-1-i] = (in and 2L^i) / 2L^i
    endfor
    
    bit_out = [[bit_out], [out]]
    
  endfor




end