#	https://github.hpe.com/ygupta/3parstats
#	Place this script in the directory whose files you want to copy to the 3PAR
#	The files will be copied to the folder /common/3PARstats inside 3PAR
#	You need to have the root access to use the following script: enter the username as 'root' and the corresponding password
# 	Please have the filename of "reportstats" file as "reportstats.pl" and "showinservstats-local" as "showinservstats-local.pl" to be read by the script correctly
import paramiko

Client = None
def send_file(ip, username, password):
	port = 22

	mypath_reportstat = r'reportstats.pl' 
	remotepath_reportstat = r'/common/3parstats/reportstats'

	mypath_showinstat = r'showinservstats-local.pl'
	remotepath_showinstat = r'/common/3parstats/showinservstats-local'

	mypath_statrcip = r'statrcip.sh'
	remotepath_statrcip = r'/common/3parstats/statrcip'

	mypath_freememory = r'freememory.sh'
	remotepath_freememory = r'/common/3parstats/freememory'

	mypath_readme = r'readme.me'
	remotepath_readme = r'/common/3parstats/readme'

	t = paramiko.Transport((ip, 22))
	t.connect(username=username, password=password)
	sftp = paramiko.SFTPClient.from_transport(t)
	try:
		sftp.mkdir("/common/3parstats")
	except:
		pass
	
	sftp.put(mypath_reportstat, remotepath_reportstat)
	sftp.chmod(remotepath_reportstat, 755)
	print("File {} is copied successfully".format(mypath_reportstat))

	sftp.put(mypath_showinstat, remotepath_showinstat)
	sftp.chmod(remotepath_showinstat, 755)
	print("File {} is copied successfully".format(mypath_showinstat))

	sftp.put(mypath_statrcip, remotepath_statrcip)
	sftp.chmod(remotepath_statrcip, 755)
	print("File {} is copied successfully".format(mypath_statrcip))

	sftp.put(mypath_freememory, remotepath_freememory)
	sftp.chmod(remotepath_freememory, 755)
	print("File {} is copied successfully".format(mypath_freememory))

	sftp.put(mypath_readme, remotepath_readme)
	sftp.chmod(remotepath_readme, 555)
	print("File {} is copied successfully".format(mypath_readme))


	t.close()

def ssh_connect(ip, username, password):
	global Client
	Client = paramiko.client.SSHClient()
	Client.set_missing_host_key_policy(paramiko.client.AutoAddPolicy())
	Client.connect(hostname=ip, username=username, password=password)
	return Client

def load_file():
	global Client
	cmd_1 = "sed -i -e 's/\r$//' showinservstats-local"
	stdin, stdout, stderr = Client.exec_command(cmd_1)
	# print(stdout.read())
	print("Executed command {} to make {} compatible for Linux Environment".format("sed -i -e 's/\r$//'", "showinservstats-local") )

	cmd_2 = "sed -i -e 's/\r$//' reportstats"
	stdin, stdout, stderr = Client.exec_command(cmd_2)
	# print(stdout.read())
	print("Executed command {} to make {} compatible for Linux Environment".format("sed -i -e 's/\r$//'", "reportstats") )

	cmd_3 = "sed -i -e 's/\r$//' statrcip"
	stdin, stdout, stderr = Client.exec_command(cmd_3)
	# print(stdout.read())
	print("Executed command {} to make {} compatible for Linux Environment".format("sed -i -e 's/\r$//'", "statrcip") )

	cmd_4 = "sed -i -e 's/\r$//' freememory"
	stdin, stdout, stderr = Client.exec_command(cmd_4)
	# print(stdout.read())
	print("Executed command {} to make {} compatible for Linux Environment".format("sed -i -e 's/\r$//'", "freememory") )	 
	
ip = input("Enter the IP Address of the machine:")
user = input("Enter the Username (default: 'root'):")
if(not len(user)):
	user = 'root'
passwd = input("Enter the password:")
if(not len(passwd)):
	print ("Please enter the password of {}".format(user))

cl = ssh_connect(ip, user, passwd)
print("The host is connected!!!")
send_file(ip, user, passwd)
load_file()
cl.close()
print("The Connection is closed!!!")


	

