pro prepare_time_plot, time_et, time_utc, time_et2

;time_utc has to be in the ISOC format


  month = strmid(time_utc[0], 5, 2)
  year = strmid(time_utc[0], 0, 4)
  day = strmid(time_utc[0], 8, 2)
  hr = strmid(time_utc[0], 11, 2)
  minu = strmid(time_utc[0], 14, 2)
  sec = strmid(time_utc[0], 17, 2)
  
  offset = JULDAY(month, day, year, hr, minu, sec)
  
  
  time_et2 = (time_et-time_et[0])/(3600.*24.) + offset


return

end