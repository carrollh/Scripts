#!ipy64

from __future__ import with_statement

import sys
import dkcore as dk

svc = dk.sdrsvc
client = dk.sdrclient
log = dk.LogManager.GetLogger('TestHarness')

# test the SDRService call to getVolumeList
def get_vol_list(server):
    result = None
    while result is None:
        try:
            result = svc.getVolumeList(server)
        except Exception, ex:
            log.Error("SDRService.getVolumeList failed " + str(ex))
            result = str(ex)
    return result
#

# test the SDRClient call to getVolumeList
def getVolList(server):
	result = None
	client.openClient(server)
	while result is None:
		try:
			volList = dk.List[dk.EmVolumeInfo]()
			result = client.getVolumeList(volList)
			if result == 0:
				result = volList
		except Exception, ex:
			log.Error("SDRClient.getVolList failed " + str(ex))
			result = str(ex)
			client.closeClient()
	client.closeClient()
	return result
#

# SDRService.getVolumeInfo to verify python is working with known good function.
def get_vol_info(server, volume):
    result = None
    while result is None:
        try:
            result = svc.getVolumeInfo(server, volume)
        except Exception, ex:
            log.Error("getVolumeInfo failed" + str(ex))
            result = str(ex)
    return result
#

# SDRClient.getVolumeInfo 
def getVolInfo(server, volume):
    result = None
    client.openClient(server)
    while result is None:
        try:
			volInfo = dk.EmVolumeInfo()
			result = client.getVolumeInfo(volume, volInfo)
			if result == 0:
				# need to make ClientLibrarySDRService.createVolumeInfo public for this to work
				result = svc.createVolumeInfo(volInfo);
				#result = volInfo # use instead of above for general testing
        except Exception, ex:
            log.Error("getVolumeInfo failed" + str(ex))
            result = str(ex)
    client.closeClient()
    return result
#
