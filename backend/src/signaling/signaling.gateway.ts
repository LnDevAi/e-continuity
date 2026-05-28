import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Logger } from '@nestjs/common';

interface SignalingOffer {
  targetDeviceId: string;
  offer: RTCSessionDescriptionInit;
  fromDeviceId: string;
}

interface SignalingAnswer {
  targetDeviceId: string;
  answer: RTCSessionDescriptionInit;
  fromDeviceId: string;
}

interface IceCandidate {
  targetDeviceId: string;
  candidate: RTCIceCandidateInit;
  fromDeviceId: string;
}

@WebSocketGateway({
  cors: { origin: '*' },
  namespace: '/signaling',
})
export class SignalingGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(SignalingGateway.name);
  // Map deviceId -> socketId pour le routage des messages
  private deviceSockets = new Map<string, string>();

  handleConnection(client: Socket) {
    this.logger.log(`Client connecté: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    // Supprimer le socket de la map quand l'appareil se déconnecte
    for (const [deviceId, socketId] of this.deviceSockets.entries()) {
      if (socketId === client.id) {
        this.deviceSockets.delete(deviceId);
        this.logger.log(`Appareil déconnecté: ${deviceId}`);
        break;
      }
    }
  }

  @SubscribeMessage('register-device')
  handleRegisterDevice(
    @MessageBody() data: { deviceId: string },
    @ConnectedSocket() client: Socket,
  ) {
    this.deviceSockets.set(data.deviceId, client.id);
    client.join(`device:${data.deviceId}`);
    this.logger.log(`Appareil enregistré: ${data.deviceId} -> ${client.id}`);
    return { registered: true, deviceId: data.deviceId };
  }

  // WebRTC Signaling : SDP Offer
  @SubscribeMessage('offer')
  handleOffer(
    @MessageBody() data: SignalingOffer,
    @ConnectedSocket() client: Socket,
  ) {
    const targetSocketId = this.deviceSockets.get(data.targetDeviceId);
    if (targetSocketId) {
      this.server.to(targetSocketId).emit('offer', {
        offer: data.offer,
        fromDeviceId: data.fromDeviceId,
      });
    }
  }

  // WebRTC Signaling : SDP Answer
  @SubscribeMessage('answer')
  handleAnswer(
    @MessageBody() data: SignalingAnswer,
    @ConnectedSocket() client: Socket,
  ) {
    const targetSocketId = this.deviceSockets.get(data.targetDeviceId);
    if (targetSocketId) {
      this.server.to(targetSocketId).emit('answer', {
        answer: data.answer,
        fromDeviceId: data.fromDeviceId,
      });
    }
  }

  // WebRTC Signaling : ICE Candidate
  @SubscribeMessage('ice-candidate')
  handleIceCandidate(
    @MessageBody() data: IceCandidate,
    @ConnectedSocket() client: Socket,
  ) {
    const targetSocketId = this.deviceSockets.get(data.targetDeviceId);
    if (targetSocketId) {
      this.server.to(targetSocketId).emit('ice-candidate', {
        candidate: data.candidate,
        fromDeviceId: data.fromDeviceId,
      });
    }
  }

  // Notifier tous les appareils d'un utilisateur d'une mise à jour du presse-papier
  broadcastClipboardUpdate(userId: string, clipboardItem: any) {
    this.server.emit(`clipboard-update:${userId}`, clipboardItem);
  }

  // Transmettre une commande Kill Switch à un appareil cible
  sendDeviceCommand(targetDeviceId: string, command: any) {
    const targetSocketId = this.deviceSockets.get(targetDeviceId);
    if (targetSocketId) {
      this.server.to(targetSocketId).emit('device-command', command);
      return true;
    }
    return false; // Appareil hors ligne — la commande sera exécutée au prochain démarrage
  }

  // Mettre à jour le statut d'un appareil (online/offline) pour tous les appareils du compte
  broadcastDeviceStatus(userId: string, deviceId: string, isOnline: boolean) {
    this.server.emit(`device-status:${userId}`, { deviceId, isOnline });
  }
}
