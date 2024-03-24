#!/usr/bin/env python3
import time
import sys
import serial
import argparse 

from serial.threaded import LineReader, ReaderThread

parser = argparse.ArgumentParser(description='LoRa Radio mode sender.')
parser.add_argument('port', help="Serial port descriptor")
args = parser.parse_args()

class PrintLines(LineReader):

    def connection_made(self, transport):
        print("connection made")
        self.transport = transport
        self.send_cmd("sys set pindig GPIO11 0")
        self.send_cmd('sys get ver')
        self.send_cmd('radio get mod')
        self.send_cmd('radio get freq')
        self.send_cmd('radio get sf')
        self.send_cmd('mac pause')
        self.send_cmd('radio set pwr 10')
        self.send_cmd("sys set pindig GPIO11 0")
        self.frame_count = 0

    def handle_line(self, data):
        if data == "ok":
            return
        print("RECV: %s" % data)

    def connection_lost(self, exc):
        if exc:
            print(exc)
        print("port closed")

    def tx(self, llm_data):
        self.send_cmd("sys set pindig GPIO11 1")
        
        # Convert the alphabet to a hex string
        hex_list = llm_data.encode().hex()
        
        txmsg = f'radio tx {hex_list}'
        self.send_cmd(txmsg)
        time.sleep(.3)
        self.send_cmd("sys set pindig GPIO11 0")
        self.frame_count = self.frame_count + 1

    def send_cmd(self, cmd, delay=.5):
        print("SEND: %s" % cmd)
        self.write_line(cmd)
        time.sleep(delay)


ser = serial.Serial(args.port, baudrate=57600)
with ReaderThread(ser, PrintLines) as protocol:
    while(1):
        with open('llm_data_bad_actor.txt', 'r') as file:
            data = file.read().replace('\n', '')
            print(data)
        protocol.tx(llm_data=data)
        time.sleep(10)
