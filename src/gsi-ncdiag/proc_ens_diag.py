def proc_ens_diag(filename):
    import netCDF4 as nc
    print("proc_ens_diag")
    fileprefix=filename[:-12]
    print(fileprefix)
    dout = nc.Dataset(filename, 'a')
    obs = dout['Observation']
    varhofxbc = dout['Obs_Minus_Forecast_adjusted']
    outvar = dout.createVariable("Forecast_adjusted", varhofxbc.datatype, varhofxbc.dimensions)
    outvar[:] = obs[:] - varhofxbc[:]
    varhofx = dout['Obs_Minus_Forecast_unadjusted']
    outvar = dout.createVariable("ObsBias", varhofx.datatype, varhofx.dimensions)
    outvar[:] = varhofxbc[:] - varhofx[:]
    var = dout['Analysis_Use_Flag']
    outvar = dout.createVariable("EffectiveQC", var.datatype, var.dimensions)
    outvar[:] = 1
    outvar[var[:]==1] = 0
    for imem in range(20):
      print(fileprefix+"_mem"+str(imem+1).zfill(3)+".nc4")
      din = nc.Dataset(fileprefix+"_mem"+str(imem+1).zfill(3)+".nc4", 'r')
      varhofx = din['Obs_Minus_Forecast_unadjusted']
      outVar = dout.createVariable("Forecast_unadjusted_"+str(imem+1), varhofx.datatype, varhofx.dimensions)
      outVar[:] = obs[:] - varhofx[:]
      din.close()
    dout.close()

def proc_ens_diag_rad(filename):
    import netCDF4 as nc
    print("proc_ens_diag_rad")
    fileprefix=filename[:-12]
    print(fileprefix)
    dout = nc.Dataset(filename, 'a')
    obs = dout['Observation']
    varhofxbc = dout['Obs_Minus_Forecast_adjusted']
    outvar = dout.createVariable("Forecast_adjusted", varhofxbc.datatype, varhofxbc.dimensions)
    outvar[:] = obs[:] - varhofxbc[:]
    varhofx = dout['Obs_Minus_Forecast_unadjusted']
    outvar = dout.createVariable("ObsBias", varhofx.datatype, varhofx.dimensions)
    outvar[:] = varhofxbc[:] - varhofx[:]
    var = dout['QC_Flag']
    outvar = dout.createVariable("EffectiveQC", var.datatype, var.dimensions)
    outvar[:] = var[:]
    for imem in range(20):
      print(fileprefix+"_mem"+str(imem+1).zfill(3)+".nc4")
      din = nc.Dataset(fileprefix+"_mem"+str(imem+1).zfill(3)+".nc4", 'r')
      varhofx = din['Obs_Minus_Forecast_unadjusted']
      outVar = dout.createVariable("Forecast_unadjusted_"+str(imem+1), varhofx.datatype, varhofx.dimensions)
      outVar[:] = obs[:] - varhofx[:]
      din.close()
    dout.close()

def proc_ens_diag_convq(filename):
    import netCDF4 as nc
    print("proc_ens_diag_convq")
    fileprefix=filename[:-12]
    print(fileprefix)
    dout = nc.Dataset(filename, 'a')
    sathum = dout['Forecast_Saturation_Spec_Hum'][:]
    obs = dout['Observation']
    obs[:] = obs[:] / sathum
    varhofxbc = dout['Obs_Minus_Forecast_adjusted']
    outvar = dout.createVariable("Forecast_adjusted", varhofxbc.datatype, varhofxbc.dimensions)
    outvar[:] = obs[:] - varhofxbc[:]/sathum
    varhofx = dout['Obs_Minus_Forecast_unadjusted']
    outvar = dout.createVariable("ObsBias", varhofx.datatype, varhofx.dimensions)
    outvar[:] = varhofxbc[:] - varhofx[:]
    var = dout['Analysis_Use_Flag']
    outvar = dout.createVariable("EffectiveQC", var.datatype, var.dimensions)
    outvar[:] = 1
    outvar[var[:]==1] = 0
    var = dout['Errinv_Input']
    var[:] = var[:] * sathum
    var = dout['Errinv_Final']
    var[:] = var[:] * sathum
    for imem in range(20):
      print(fileprefix+"_mem"+str(imem+1).zfill(3)+".nc4")
      din = nc.Dataset(fileprefix+"_mem"+str(imem+1).zfill(3)+".nc4", 'r')
      varhofx = din['Obs_Minus_Forecast_unadjusted']
      outVar = dout.createVariable("Forecast_unadjusted_"+str(imem+1), varhofx.datatype, varhofx.dimensions)
      outVar[:] = obs[:] - varhofx[:]/sathum
      din.close()
    dout.close()

def proc_ens_diag_convuv(filename):
    import netCDF4 as nc
    print("proc_ens_diag_convuv")
    fileprefix=filename[:-12]
    print(fileprefix)
    dout = nc.Dataset(filename, 'a')
    obs = dout['u_Observation']
    varhofxbc = dout['u_Obs_Minus_Forecast_adjusted']
    outvar = dout.createVariable("u_Forecast_adjusted", varhofxbc.datatype, varhofxbc.dimensions)
    outvar[:] = obs[:] - varhofxbc[:]
    varhofx = dout['u_Obs_Minus_Forecast_unadjusted']
    outvar = dout.createVariable("u_ObsBias", varhofx.datatype, varhofx.dimensions)
    outvar[:] = varhofxbc[:] - varhofx[:]
    var = dout['Analysis_Use_Flag']
    outvar = dout.createVariable("EffectiveQC", var.datatype, var.dimensions)
    outvar[:] = 1
    outvar[var[:]==1] = 0
    for imem in range(20):
      print(fileprefix+"_mem"+str(imem+1).zfill(3)+".nc4")
      din = nc.Dataset(fileprefix+"_mem"+str(imem+1).zfill(3)+".nc4", 'r')
      varhofx = din['u_Obs_Minus_Forecast_unadjusted']
      outVar = dout.createVariable("u_Forecast_unadjusted_"+str(imem+1), varhofx.datatype, varhofx.dimensions)
      outVar[:] = obs[:] - varhofx[:]
      din.close()
    obs = dout['v_Observation']
    varhofxbc = dout['v_Obs_Minus_Forecast_adjusted']
    outvar = dout.createVariable("v_Forecast_adjusted", varhofxbc.datatype, varhofxbc.dimensions)
    outvar[:] = obs[:] - varhofxbc[:]
    varhofx = dout['v_Obs_Minus_Forecast_unadjusted']
    outvar = dout.createVariable("v_ObsBias", varhofx.datatype, varhofx.dimensions)
    outvar[:] = varhofxbc[:] - varhofx[:]
    for imem in range(20):
      print(fileprefix+"_mem"+str(imem+1).zfill(3)+".nc4")
      din = nc.Dataset(fileprefix+"_mem"+str(imem+1).zfill(3)+".nc4", 'r')
      varhofx = din['v_Obs_Minus_Forecast_unadjusted']
      outVar = dout.createVariable("v_Forecast_unadjusted_"+str(imem+1), varhofx.datatype, varhofx.dimensions)
      outVar[:] = obs[:] - varhofx[:]
      din.close()
    dout.close()
